---
title: Chat With Factory
description: A voice-enabled AI agent web application for industrial environments powered by Azure AI Foundry Agents or Copilot Studio
ms.date: 2026-06-29
ms.topic: overview
keywords:
  - chat with factory
  - voice agent
  - azure ai foundry
  - copilot studio
  - agents sdk
  - direct line
  - speech-to-text
  - industrial
---

A web application that captures voice input, sends recognized text to an AI agent, and displays the conversation in a chat panel. Designed for hands-free access to AI-powered guidance in industrial environments. Runs standalone or optionally inside Microsoft Teams.

The app supports three configurable agent backends:

* **Copilot Studio via Agents SDK** (default) with OBO token exchange and streaming responses
* **Azure AI Foundry Agents** with a tool-calling run loop (handles `requires_action` for the factory ontology tool)
* **Copilot Studio via Direct Line API 3.0** with asynchronous WebSocket relay

Set `AGENT_BACKEND` in `.env` to `copilotstudio`, `foundry`, or `directline` to choose.

## Prerequisites

* Azure subscription with sufficient quota
* Edge cluster, ACR, and Azure AI Foundry deployed via the
  [full-multi-node-cluster](../../../blueprints/full-multi-node-cluster/) blueprint
* Microsoft Fabric workspace deployed via the
  [fabric](../../../blueprints/fabric/) blueprint
* CORA/CORAX ontology provisioned into that workspace via
  [033-fabric-ontology](../../000-cloud/033-fabric-ontology/README.md)
* `kubectl` and `helm` installed locally

## Setup

### Setup Prerequisites

* [Node.js](https://nodejs.org/) v21 or later
* Azure CLI authenticated (`az login`)
* [Dev tunnels CLI](https://learn.microsoft.com/azure/developer/dev-tunnels/get-started) (`devtunnel`) for Teams testing
* Teams Developer Portal access (for sideloading)
* One of the following agent backends:
  * A published Copilot Studio agent with Agents SDK access (`AGENT_BACKEND=copilotstudio`, default)
  * An Azure AI Foundry project with a deployed agent (`AGENT_BACKEND=foundry`)
  * A published Copilot Studio agent with a web channel secret (`AGENT_BACKEND=directline`)

### Azure Resource Setup

Create the resources in order. All steps use Azure CLI and PowerShell.

```powershell
az login
devtunnel user login
```

#### 1. Dev Tunnel

Create the tunnel first because the Entra app registration needs the hostname. You only run `devtunnel create` once. After that, rehost the same tunnel to keep a stable hostname.

```powershell
# One-time setup: create a persistent tunnel and add port 3978
devtunnel create --allow-anonymous
devtunnel port create -p 3978
```

Note the tunnel ID from the output (for example, `happy-forest-1234`). The hostname follows the pattern `<tunnel-id>-3978.use.devtunnels.ms`.

```powershell
# Every time you develop: rehost the existing tunnel (hostname stays the same)
devtunnel host <tunnel-id>
```

Set the hostname variable in a separate terminal for the remaining steps:

```powershell
$TUNNEL_HOST = "<tunnel-id>-3978.use.devtunnels.ms"   # e.g. happy-forest-1234-3978.use.devtunnels.ms
```

> [!TIP]
> Run `devtunnel host` in a separate terminal. It must stay running while you test in Teams. Use `devtunnel list` to see all your existing tunnels if you forget the ID.

#### 2. Entra ID App Registration (Teams SSO)

Create the app registration, expose the `access_as_user` scope, and authorize Teams clients.

```powershell
# Create the registration with User.Read permission
# resourceAppId 00000003-... is the well-known public Microsoft Graph app ID;
# the scope id e1fe6dd8-... is Graph's well-known User.Read delegated permission.
az ad app create `
  --display-name "chat-with-your-factory-sso" `
  --sign-in-audience AzureADMyOrg `
  --enable-id-token-issuance true `
  --requested-access-token-version 2 `
  --required-resource-accesses '[{\"resourceAppId\":\"00000003-0000-0000-c000-000000000000\",\"resourceAccess\":[{\"id\":\"e1fe6dd8-ba31-4d61-89e7-88639da4683d\",\"type\":\"Scope\"}]}]'

# Capture the IDs
$CLIENT_ID = az ad app list --display-name "chat-with-your-factory-sso" --query "[0].appId" -o tsv
$OBJECT_ID = az ad app list --display-name "chat-with-your-factory-sso" --query "[0].id" -o tsv
$TENANT_ID = az account show --query tenantId -o tsv

# Set the Application ID URI
az ad app update --id $CLIENT_ID `
  --identifier-uris "api://$TUNNEL_HOST/$CLIENT_ID"
```

Add the `access_as_user` scope, then authorize both Teams clients. This requires two PATCH calls because Graph rejects pre-authorized app references to scopes that do not exist yet. Both calls use a temp file because `az rest --body` does not reliably parse inline JSON on Windows.

```powershell
$SCOPE_ID = [guid]::NewGuid().ToString()
$tempFile = Join-Path $env:TEMP "graph-body.json"

# Step 1: Create the scope
@{
  api = @{
    oauth2PermissionScopes = @(@{
      adminConsentDescription = "Allow the application to access Chat With Factory APIs as the signed-in user"
      adminConsentDisplayName = "Access as user"
      id                      = $SCOPE_ID
      isEnabled               = $true
      type                    = "User"
      userConsentDescription  = "Allow the application to call Chat With Factory APIs on your behalf"
      userConsentDisplayName  = "Access as user"
      value                   = "access_as_user"
    })
  }
} | ConvertTo-Json -Depth 5 | Out-File -FilePath $tempFile -Encoding utf8NoBOM -Force

az rest --method PATCH `
  --uri "https://graph.microsoft.com/v1.0/applications/$OBJECT_ID" `
  --headers "Content-Type=application/json" `
  --body "@$tempFile"

# Step 2: Add pre-authorized Teams clients (scope must exist first)
@{
  api = @{
    oauth2PermissionScopes = @(@{
      adminConsentDescription = "Allow the application to access Chat With Factory APIs as the signed-in user"
      adminConsentDisplayName = "Access as user"
      id                      = $SCOPE_ID
      isEnabled               = $true
      type                    = "User"
      userConsentDescription  = "Allow the application to call Chat With Factory APIs on your behalf"
      userConsentDisplayName  = "Access as user"
      value                   = "access_as_user"
    })
    # The two appIds below are Microsoft's well-known, public Teams first-party
    # client IDs (not tenant-specific) and are required for Teams SSO pre-auth.
    preAuthorizedApplications = @(
      @{ appId = "1fec8e78-bce4-4aaf-ab1b-5451cc387264"; delegatedPermissionIds = @($SCOPE_ID) }  # Teams web client
      @{ appId = "5e3ce6c0-2b1f-4285-8d4b-75ee78787346"; delegatedPermissionIds = @($SCOPE_ID) }  # Teams desktop/mobile client
    )
  }
} | ConvertTo-Json -Depth 5 | Out-File -FilePath $tempFile -Encoding utf8NoBOM -Force

az rest --method PATCH `
  --uri "https://graph.microsoft.com/v1.0/applications/$OBJECT_ID" `
  --headers "Content-Type=application/json" `
  --body "@$tempFile"
```

> [!NOTE]
> Both PATCH calls return no output on success (HTTP 204). If you see a `BadRequest` error, verify that `$OBJECT_ID` and `$SCOPE_ID` are set in your current terminal session.

Create a service principal for the app:

```powershell
az ad sp create --id $CLIENT_ID
```

Grant admin consent for `User.Read` (requires Global Admin or Privileged Role Administrator):

```powershell
az ad app permission grant `
  --id $(az ad sp show --id $CLIENT_ID --query id -o tsv) `
  --api $(az ad sp show --id "00000003-0000-0000-c000-000000000000" --query id -o tsv) ` # well-known Microsoft Graph app ID
  --scope "User.Read"
```

> [!TIP]
> If this fails with "Insufficient privileges," you can skip it. The `User.Read` permission was already declared on the app during creation. Users see a one-time consent prompt instead. Alternatively, ask a tenant admin to grant consent in Azure Portal > App registrations > API permissions > Grant admin consent.

Print the values you need for configuration:

```powershell
Write-Host "TEAMS_APP_ID=$CLIENT_ID"
Write-Host "AZURE_TENANT_ID=$TENANT_ID"
```

#### 3. Azure AI Foundry Project

> [!NOTE]
> Only required when using the Foundry backend (`AGENT_BACKEND=foundry` or unset). Skip to [Copilot Studio (Direct Line)](#4-copilot-studio-direct-line) if using Direct Line.

Create the Foundry resource, project, and model deployment:

```powershell
$RG_NAME   = "rg-chat-with-your-factory"
$LOCATION  = "eastus"
$AI_NAME   = "chat-factory-ai"
$PROJECT   = "chat-factory-project"

az group create --name $RG_NAME --location $LOCATION

az cognitiveservices account create `
  --name $AI_NAME `
  --resource-group $RG_NAME `
  --kind AIServices `
  --sku S0 `
  --location $LOCATION `
  --custom-domain $AI_NAME

az cognitiveservices account deployment create `
  --name $AI_NAME `
  --resource-group $RG_NAME `
  --deployment-name gpt-4o `
  --model-name gpt-4o `
  --model-version "2024-11-20" `
  --model-format OpenAI `
  --sku-capacity 1 `
  --sku-name Standard
```

Create the agent via REST (the Foundry CLI does not support assistants-style agent creation):

```powershell
$FOUNDRY_ENDPOINT = "https://${AI_NAME}.services.ai.azure.com/api/projects/${PROJECT}"
$TOKEN = az account get-access-token --resource "https://cognitiveservices.azure.com" --query accessToken -o tsv

$AGENT_RESPONSE = Invoke-RestMethod -Method Post `
  -Uri "$FOUNDRY_ENDPOINT/assistants?api-version=2025-05-01" `
  -Headers @{ Authorization = "Bearer $TOKEN"; "Content-Type" = "application/json" } `
  -Body '{"model":"gpt-4o","name":"maintenance-agent","instructions":"You are a maintenance scheduling assistant for industrial machines."}'

$AGENT_ID = $AGENT_RESPONSE.id

Write-Host "FOUNDRY_ENDPOINT=$FOUNDRY_ENDPOINT"
Write-Host "FOUNDRY_AGENT_ID=$AGENT_ID"
```

#### 4. Copilot Studio (Direct Line)

> [!NOTE]
> Only required when using the Direct Line backend (`AGENT_BACKEND=directline`). Skip this if using Foundry or Agents SDK.

The Direct Line backend connects to a Copilot Studio agent via the Direct Line API 3.0. The server holds the channel secret and proxies all messages through a WebSocket relay.

##### Create and configure the Copilot Studio agent

1. Go to [Copilot Studio](https://copilotstudio.microsoft.com/) and create or open your agent.
2. Configure the agent's topics, knowledge sources, and authentication as needed.
3. **Publish** the agent (required; unpublished agents return `LatestPublishedVersionNotFound`).

##### Get the web channel secret

1. In Copilot Studio, go to **Settings** > **Channels** > **Custom website**.
2. Copy either **Secret 1** or **Secret 2** (two secrets are provided for zero-downtime rotation).
3. Set `DIRECT_LINE_SECRET` in your `.env` to the copied secret.

##### Configure the environment

Set these variables in `.env`:

```bash
AGENT_BACKEND=directline
DIRECT_LINE_SECRET=<your-copilot-studio-web-channel-secret>
```

Optionally set a regional endpoint if your agent is in a specific region:

```bash
DIRECT_LINE_ENDPOINT=https://europe.directline.botframework.com
```

The default endpoint is `https://directline.botframework.com`.

##### Verify the connection

```bash
npm start
```

Open the app (localhost or via dev tunnel). Create a session; the server logs `[DirectLine] WebSocket connected for session ...` on success. Send a message and verify the agent responds via SSE.

##### Direct Line Troubleshooting

| Error                                           | Cause                                 | Fix                                                               |
|-------------------------------------------------|---------------------------------------|-------------------------------------------------------------------|
| `LatestPublishedVersionNotFound`                | Agent not published                   | Publish the agent in Copilot Studio                               |
| `AuthenticationNotConfigured`                   | Agent's knowledge source auth missing | Configure authentication in Copilot Studio Settings > Security    |
| `Failed to start Direct Line conversation: 403` | Invalid or expired secret             | Copy a fresh secret from Copilot Studio Channels > Custom website |
| `DIRECT_LINE_SECRET is required`                | Env var missing                       | Add `DIRECT_LINE_SECRET` to `.env`                                |

#### 5. Copilot Studio (Agents SDK)

> [!NOTE]
> Only required when using the Agents SDK backend (`AGENT_BACKEND=copilotstudio`, the default). Skip this if using Foundry or Direct Line.

The Agents SDK backend connects to a Copilot Studio agent using `@microsoft/agents-copilotstudio-client` with OBO (On-Behalf-Of) token exchange. The server exchanges the Teams SSO token for a Power Platform token via MSAL.

##### App registration: add a client secret

1. In Azure Portal, go to **App registrations** > your chat-with-your-factory registration.
2. Under **Certificates & secrets** > **Client secrets**, click **New client secret**.
3. Copy the secret value and set `TEAMS_APP_CLIENT_SECRET` in your `.env`.

##### App registration: add Power Platform API consent

1. In Azure Portal, go to **App registrations** > your app > **API permissions**.
2. Click **Add a permission** > **APIs my organization uses**.
3. Search for **Power Platform API** (well-known public Microsoft app ID `8578e004-a5c6-46e7-913e-12f58912df43`). If it does not appear, create the service principal first:

   ```powershell
   az ad sp create --id 8578e004-a5c6-46e7-913e-12f58912df43  # well-known Power Platform API app ID
   ```

4. Select **Delegated permissions**, check the default scope, and click **Add permissions**.
5. Click **Grant admin consent** (requires Global Admin or Privileged Role Administrator).

##### Find your CPS_ENVIRONMENT_ID

Open [Copilot Studio](https://copilotstudio.microsoft.com/) and select your agent. The environment ID is in the URL:

```text
https://copilotstudio.microsoft.com/environments/<ENVIRONMENT_ID>/agents/...
```

##### Find your CPS_AGENT_IDENTIFIER

1. In [Power Apps](https://make.powerapps.com/), go to **Solutions** > **Default Solution**.
2. Filter by **Copilot** type and find your agent.
3. The **Name** column shows the schema name (for example, `crd49_YourAgent`). Use this as `CPS_AGENT_IDENTIFIER`.

##### Find your CPS_DIRECT_CONNECT_URL (optional)

If you prefer to use the direct connect URL instead of environment ID and agent identifier:

1. In Copilot Studio, go to **Settings** > **Channels** > **Web app**.
2. Copy the **Direct connect URL**.
3. Set `CPS_DIRECT_CONNECT_URL` in your `.env`. When set, this overrides `CPS_ENVIRONMENT_ID` and `CPS_AGENT_IDENTIFIER`.

##### Configure the environment for Copilot Studio

Set these variables in `.env`:

```bash
AGENT_BACKEND=copilotstudio
CPS_ENVIRONMENT_ID=<power-platform-environment-id>
CPS_AGENT_IDENTIFIER=<copilot-schema-name>
TEAMS_APP_CLIENT_SECRET=<client-secret-from-app-registration>
```

##### Verify the Copilot Studio connection

```bash
npm start
```

Open the app in Teams (OBO exchange requires a real Teams SSO token; `SKIP_AUTH=true` does not work with this backend). Create a session and send a message. The server logs `[CopilotStudio] Streaming reply for session ...` on success.

### Configuration Files

> [!NOTE]
> The app supports three agent backends. Set `AGENT_BACKEND` in `.env` to choose which one to use.
> Copilot Studio Agents SDK variables (`CPS_ENVIRONMENT_ID`, `CPS_AGENT_IDENTIFIER`, `TEAMS_APP_CLIENT_SECRET`) are only required when `AGENT_BACKEND=copilotstudio` (the default).
> Foundry-specific variables (`FOUNDRY_ENDPOINT`, `FOUNDRY_AGENT_ID`) are only required when `AGENT_BACKEND=foundry`.
> Direct Line variables (`DIRECT_LINE_SECRET`) are only required when `AGENT_BACKEND=directline`.

#### Environment variables (`.env`)

Copy from `.env.template` if the file does not exist.

| Variable                   | Required     | Description                                                                                                           |
|----------------------------|--------------|-----------------------------------------------------------------------------------------------------------------------|
| `FOUNDRY_ENDPOINT`         | Foundry only | Azure AI Foundry project endpoint                                                                                     |
| `FOUNDRY_AGENT_ID`         | Foundry only | Foundry agent/assistant ID                                                                                            |
| `AZURE_TENANT_ID`          | Yes          | Entra ID tenant                                                                                                       |
| `TEAMS_APP_ID`             | Yes          | Entra app registration client ID                                                                                      |
| `DEVTUNNEL_DOMAIN`         | Teams dev    | Dev tunnel hostname, e.g. `abc123-3978.use.devtunnels.ms`                                                             |
| `AGENT_BACKEND`            | No           | `copilotstudio`, `directline`, or `foundry` (default: `copilotstudio`)                                                |
| `DIRECT_LINE_SECRET`       | DL only      | Copilot Studio web channel secret                                                                                     |
| `DIRECT_LINE_ENDPOINT`     | No           | Regional DL endpoint (default: `directline.botframework.com`)                                                         |
| `CPS_ENVIRONMENT_ID`       | CPS only     | Power Platform environment ID                                                                                         |
| `CPS_AGENT_IDENTIFIER`     | CPS only     | Copilot agent schema name (e.g., `crd49_YourAgent`)                                                                   |
| `CPS_DIRECT_CONNECT_URL`   | No           | Direct connect URL from Copilot Studio Channels > Web app (overrides `CPS_ENVIRONMENT_ID` and `CPS_AGENT_IDENTIFIER`) |
| `TEAMS_APP_CLIENT_SECRET`  | CPS only     | Client secret from app registration (for OBO exchange)                                                                |
| `PORT`                     | No           | Server port (default: `3978`)                                                                                         |
| `SKIP_AUTH`                | No           | Set `true` for local dev without Teams                                                                                |
| `AZURE_SPEECH_REGION`      | Speech only  | Azure Speech Services region                                                                                          |
| `AZURE_SPEECH_RESOURCE_ID` | Speech only  | Azure Speech resource name                                                                                            |

#### Teams manifest (`appManifest/manifest.json`)

Copy from `manifest.TEMPLATE.json` and fill in:

| Field                         | Value                                |
|-------------------------------|--------------------------------------|
| `id`                          | A new GUID (`[guid]::NewGuid()`)     |
| `staticTabs[0].contentUrl`    | `https://<tunnel-hostname>`          |
| `validDomains[0]`             | `<tunnel-hostname>`                  |
| `webApplicationInfo.id`       | `$CLIENT_ID`                         |
| `webApplicationInfo.resource` | `api://<tunnel-hostname>/$CLIENT_ID` |

#### Switching Tenants or Subscriptions

When moving to a new tenant or subscription, repeat the steps above and re-authenticate:

```powershell
az login --tenant <new-tenant-id>
```

All Foundry API calls use `DefaultAzureCredential`, which picks up the active `az login` session.

## Architecture

### Architecture Detail

#### Current (Prototype)

The app follows a standard client/server split. The Teams client hosts the tab in an iframe, the React client manages the UI and Teams integration, and the Express server mediates all communication with the agent backend (Copilot Studio via Agents SDK, Azure AI Foundry, or Copilot Studio via Direct Line).

```text
┌─────────────────────────────────────────────────────────┐
│  Teams Client (Web / Desktop)                           │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │ Speech input │  │ React 18 +   │  │ Teams JS SDK  │  │
│  │ (Web Speech  │──│ Fluent UI v9 │──│ v2 (SSO,      │  │
│  │  or Azure)   │  │              │  │ theme, people)│  │
│  └──────────────┘  └──────┬───────┘  └───────────────┘  │
│                          │ REST (fetch + Bearer token)  │
└──────────────────────────┼──────────────────────────────┘
                           │
┌──────────────────────────┼──────────────────────────────┐
│  Express v5 Server       │                              │
│                          ▼                              │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │ JWT auth     │  │ Session      │  │ Chat handler  │  │
│  │ (jose JWKS)  │  │ store        │  │ (conditional) │  │
│  └──────────────┘  └──────────────┘  └───────┬───────┘  │
│                                              │          │
└──────────────────────────────────────────────┼──────────┘
                                               │
          ┌────────────────────────────────────┼────────────────────────────┐
          │                          ┌─────────┼─────────┐                 │
          │                          │         │         │                 │
┌─────────▼──────────┐  ┌────────────▼───┐  ┌──▼───────────────────┐       │
│  Copilot Studio    │  │  Azure AI      │  │  Copilot Studio      │      │
│  (Agents SDK)      │  │  Foundry       │  │  (Direct Line 3.0)   │      │
│  Auth: OBO Token   │  │  Agents API    │  │  Auth: Channel Secret│      │
│                    │  │  Auth: AAD     │  │                      │      │
└────────────────────┘  └────────────────┘  └──────────────────────┘      │
                                                                          │
          Selected by AGENT_BACKEND env var (default: copilotstudio)       │
          ────────────────────────────────────────────────────────────────┘
```

The `AGENT_BACKEND` environment variable (`copilotstudio`, `foundry`, or `directline`) controls which backend the server uses. The default is `copilotstudio`. All three backends share the same session store, SSE broadcast, and client interface.

#### MVP Architecture

```text
┌──────────────────────────────────────────────────────────────────────────┐
│  Teams Client (Web / Desktop / Mobile)                                   │
│                                                                          │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────┐  ┌───────────┐  │
│  │ Adaptive      │  │ React 18 +    │  │ Teams JS SDK │  │ Audio     │  │
│  │ Cards JS SDK  │  │ Fluent UI v9  │  │ v2 (SSO,     │  │ streaming │  │
│  │ (structured   │  │ (chat panel,  │  │ theme,       │  │ (WebSocket│  │
│  │  responses)   │  │  session bar) │  │ people,      │  │  to server│  │
│  │               │  │               │  │ deep links)  │  │  for STT) │  │
│  └───────┬───────┘  └───────┬───────┘  └──────┬───────┘  └─────┬─────┘  │
│          │                  │                  │                │        │
│          └──────────────────┴─────┬────────────┘                │        │
│                                   │ REST + SSE                  │        │
│                                   │ (Bearer token)              │        │
└───────────────────────────────────┼─────────────────────────────┼────────┘
                                    │                             │
┌───────────────────────────────────┼─────────────────────────────┼────────┐
│  Azure App Service (Node 22 LTS) │                              │        │
│  Managed Identity + Key Vault    │                              │        │
│                                  ▼                              ▼        │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐  ┌───────────┐   │
│  │ JWT auth     │  │ Session      │  │ Chat handler  │  │ Azure     │   │
│  │ (jose JWKS)  │  │ store        │  │ (Foundry SDK  │  │ Speech    │   │
│  │              │  │ (Redis)      │  │  streaming)   │  │ SDK (STT  │   │
│  │              │  │              │  │               │  │  + TTS)   │   │
│  └──────────────┘  └──────┬───────┘  └───────┬───────┘  └─────┬─────┘   │
│                           │                  │                │         │
└───────────────────────────┼──────────────────┼────────────────┼─────────┘
                            │                  │                │
             ┌──────────────▼───┐  ┌───────────▼──────────┐  ┌──▼────────────────┐
             │  Azure Cache     │  │  Azure AI Foundry    │  │  Azure Speech     │
             │  for Redis       │  │  Agents API          │  │  Service           │
             │  (hot cache,     │  │  (streaming runs     │  │  (real-time STT,   │
             │   30-day TTL)    │  │   + file search +    │  │   neural TTS)      │
             │                  │  │   vector store)      │  │                    │
             │  Auth: Managed   │  │  Auth: Managed       │  │  Auth: Managed     │
             │  Identity        │  │  Identity (RBAC)     │  │  Identity           │
             └──────────────────┘  └──────────────────────┘  └────────────────────┘
                    │                         │
             ┌──────▼──────────────────────────▼──────────────────────────────────┐
             │                    Durable Storage Layer                           │
             │                                                                   │
             │  ┌──────────────────┐   indexer    ┌────────────────────────┐      │
             │  │  Blob Storage    │─────────────►│  Azure AI Search       │      │
             │  │  (system of      │   (auto)     │  (query layer:         │      │
             │  │   record)        │              │   session listing,     │      │
             │  │                  │              │   transcript search,   │      │
             │  │  transcripts/    │              │   manager review)      │      │
             │  │   {sessionId}    │              │                        │      │
             │  │   .json          │              │  Auth: Managed         │      │
             │  │                  │              │  Identity               │      │
             │  └──────────────────┘              └────────────────────────┘      │
             │                                                                   │
             └───────────────────────────────────────────────────────────────────┘
                                              │
                                   ┌──────────▼──────────┐
                                   │  Application        │
                                   │  Insights           │
                                   │  (distributed       │
                                   │   tracing, alerts)  │
                                   └─────────────────────┘
```

**Key MVP changes from prototype:**

* **Server-side STT/TTS** via Azure Speech SDK replaces browser-only Web Speech API
* **SSE streaming** replaces blocking `createAndPoll`
* **Redis** as hot cache for active sessions (30-day TTL), with **Blob Storage** as durable system of record and **Azure AI Search** as the query layer
* **Foundry vector store** ingests archived transcripts so the agent references past maintenance history
* **Adaptive Cards** for structured agent responses (work orders, checklists, approvals)
* **Managed Identity** replaces `.env` secrets
* **Application Insights** replaces `console.log`

### Technology Stack

Each concern maps to a specific technology. No component serves double duty. The **MVP Upgrade** column shows what each component needs to reach production quality.

| Concern                   | Technology                                                                       | Details                                                                                                                                                                                                                                                                                                     | MVP Upgrade                                                                                                                                          |
|---------------------------|----------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| Speech-to-text (STT)      | Configurable: Azure Speech SDK (default) or Browser Web Speech API or Voice Live | Build-time switch via `npm run build:client:azure`, `npm run build:client:webspeech`, or `npm run build:client:voicelive`. esbuild tree-shakes the unused providers at build time. Voice Live (`VOICE_PROVIDER=voicelive`) uses a server-proxied WebSocket bridge at `/api/voice-live` — see ADR 0001.      | Server-side real-time STT via Azure Speech SDK. Browser streams raw audio to Express server via WebSocket; server runs Speech SDK for transcription. |
| Text-to-speech (TTS)      | None today                                                                       | Voice Live can produce TTS in principle, but the current bridge runs it as STT/VAD only (`modalities: ['text']`, `create_response: false`) — see ADR 0001. Agent responses render as text in all configurations.                                                                                            | Azure Speech neural TTS for optional read-aloud via `/api/tts` endpoint, or enable Voice Live audio output once topology supports it.                |
| AI / LLM backend          | Copilot Studio (Agents SDK), Azure AI Foundry, or Copilot Studio (Direct Line)   | Configurable via `AGENT_BACKEND` env var (`copilotstudio` default). Agents SDK uses `@microsoft/agents-copilotstudio-client` with OBO token exchange and streaming. Foundry uses Assistants-style threads with `createAndPoll`. Direct Line uses fire-and-forget POST with WebSocket relay for bot replies. | Foundry streaming via `createAndStream` + SSE for real-time token delivery.                                                                          |
| Server framework          | Express v5 (TypeScript, ESM)                                                     | Serves static files, REST API routes, SSE broadcast, and `Permissions-Policy` header for iframe microphone access.                                                                                                                                                                                          | Same. Native async error handling. Managed Identity via `DefaultAzureCredential` in production.                                                      |
| User authentication       | Teams SSO + JWT validation (`jose`)                                              | Validates AAD v2.0 tokens. Dev bypass via `SKIP_AUTH=true`.                                                                                                                                                                                                                                                 | Remove `SKIP_AUTH` bypass in production.                                                                                                             |
| Session storage (hot)     | In-memory `Map<string, Session>`                                                 | All sessions reset on server restart.                                                                                                                                                                                                                                                                       | Azure Cache for Redis (Basic C0) with 30-day TTL.                                                                                                    |
| Session storage (durable) | None                                                                             | Sessions lost on restart.                                                                                                                                                                                                                                                                                   | Azure Blob Storage as system of record + Azure AI Search as query layer.                                                                             |
| Collaboration             | Teams JS SDK v2 people picker + deep links                                       | Native Teams people picker for adding collaborators. Deep links open group chats with the tab pre-installed.                                                                                                                                                                                                | Automatic session sync via Graph API. SSE push for real-time updates.                                                                                |
| Hosting and secrets       | localhost + dev tunnels; `.env` file                                             | Local development only.                                                                                                                                                                                                                                                                                     | Azure App Service + Key Vault references.                                                                                                            |
| Observability             | `console.log` / `console.error`                                                  | No structured telemetry.                                                                                                                                                                                                                                                                                    | Azure Application Insights with distributed tracing.                                                                                                 |

### Data Flow

A single user interaction follows this path:

1. The user clicks the mic button or types a message.
2. For voice: the `useSpeech` barrel hook delegates to either the Web Speech API, Azure Speech SDK, or Voice Live hook based on the build-time `__SPEECH_PROVIDER__` constant.
3. For Web Speech and Azure Speech providers, the React client sends a POST to `/api/chat` with the message text. For Voice Live, the browser sends raw PCM16 audio over a WebSocket to `/api/voice-live`; the server bridge handles transcription and agent dispatch (via `dispatchChat`) — no `/api/chat` POST is made for voice turns. Agent responses arrive via SSE and render as text (no TTS playback today).
4. The Express server validates the JWT, checks the user's session ACL, stores the user message locally, and broadcasts it via SSE.
5. **Copilot Studio (Agents SDK) backend**: The server performs an OBO token exchange using MSAL, connects to the Copilot Studio agent via `@microsoft/agents-copilotstudio-client`, streams the response, stores it locally, broadcasts via SSE, and returns it in the HTTP response.
6. **Foundry backend**: The server forwards the message to the Foundry agent via `agentsClient.messages.create`, calls `createAndPoll`, retrieves the response, stores it locally, broadcasts via SSE, and returns it in the HTTP response.
7. **Direct Line backend**: The server sends the message to Copilot Studio via Direct Line POST (fire-and-forget) and returns immediately. The bot's reply arrives via WebSocket, gets stored locally, and is broadcast to the client via SSE.
8. The React client displays the response in the chat panel (from either the HTTP response body or SSE event).

### API Routes

| Method | Route                             | Purpose                                        |
|--------|-----------------------------------|------------------------------------------------|
| POST   | `/api/chat`                       | Send a message to the agent and get a response |
| GET    | `/api/sessions`                   | List the current user's sessions               |
| POST   | `/api/sessions`                   | Create a new session                           |
| PATCH  | `/api/sessions/:id`               | Update session title or status                 |
| POST   | `/api/sessions/:id/participants`  | Add a participant to a session                 |
| GET    | `/api/transcript/:sessionId`      | Fetch the full message history for a session   |
| GET    | `/api/sessions/:sessionId/events` | SSE stream for real-time message relay         |
| GET    | `/api/speech-token`               | Issue a short-lived Azure Speech auth token    |

## Factory Ontology Tool

When using the Foundry backend, the agent is provisioned with a read-only
`query_factory_ontology` function tool. The tool answers robot questions by
querying the static CORA/CORAX ontology in the `RoboticsOntologyLH` Fabric
lakehouse (deployed by [033-fabric-ontology](../../000-cloud/033-fabric-ontology/README.md)).
The service runs the tool call in the backend during the agent run and submits
the result back to Foundry.

* Intents: `list_robots` (enumerate robots) and `robot_position` (a robot's pose).
* Sample questions and the seed entity catalog: [docs/factory-tool-grounding.md](docs/factory-tool-grounding.md).
* Future live-data path (interface-stable): [docs/factory-tool-live-data.md](docs/factory-tool-live-data.md).

### Tool Prerequisites

* Provision the agent with `npm run provision:agent` (attaches the tool).
* Set the Fabric connection env vars: `FABRIC_WORKSPACE_ID` + `FABRIC_LAKEHOUSE_ID`
  (host discovery via Fabric REST) or `FABRIC_SQL_ENDPOINT` (explicit host), plus
  optional `FABRIC_LAKEHOUSE_DATABASE` (default `RoboticsOntologyLH`).
* RBAC: the backend identity (`DefaultAzureCredential`) needs lakehouse read access;
  the SQL connection uses scope `https://database.windows.net/.default`.

## Development

### Development Quick Start

1. Install dependencies:

   ```bash
   npm install
   ```

2. Copy the environment template and fill in your values (see [Setup](#setup) for details):

   ```bash
   cp .env.template .env
   ```

3. Build and start the server:

   ```bash
   npm start
   ```

   This runs `npm run build` (TypeScript server compilation + esbuild client bundle) then starts the Express server on port 3978.

### Local Testing (Without Teams)

1. Set `SKIP_AUTH=true` in your `.env` file to bypass JWT validation.
2. Open `http://localhost:3978` in Chrome or Edge.
3. Click the mic button and speak, or type a message.
4. The agent response appears in the chat panel.

> [!TIP]
> The default speech provider (Azure Speech SDK) works across all browsers. To use the browser Web Speech API instead (Chrome/Edge only), run `npm run start:webspeech`. To use Voice Live (preview), set `VOICE_PROVIDER=voicelive` and `AZURE_VOICELIVE_RESOURCE` in `.env`, then run `npm run start:voicelive`. See ADR 0001 for details. The text input fallback is always available.
>
> Plain `npm start` always rebuilds the client with the **default Azure Speech SDK** provider, which will overwrite any voicelive / webspeech bundle you previously built. Use `npm run start:voicelive` or `npm run start:webspeech` to keep the matching client bundle in sync with the server in one step.

### Testing in Teams

1. Start a dev tunnel:

   ```bash
   devtunnel host -p 3978 --allow-anonymous
   ```

   Note the tunnel hostname (for example, `abc123.usw2.devtunnels.ms`).

2. Update `appManifest/manifest.json` (see [Setup](#teams-manifest-appmanifestmanifestjson) for field mappings).

3. Zip the manifest folder:

   ```powershell
   Compress-Archive -Path appManifest\* -DestinationPath manifest.zip -Force
   ```

4. Sideload in Teams:
   * Open Teams > **Apps** > **Manage your apps**.
   * Click **Upload an app** > **Upload a custom app**.
   * Select `manifest.zip` and click **Add**.

5. Open as a **personal tab** (default sidebar experience):
   * Open the **Chat With Factory** personal tab from the left sidebar.

6. Or add to a **group chat** (enables the native People panel):
   * Open or create a group chat in Teams.
   * Click the **+** (Add a tab) button in the group chat header.
   * Search for **Chat With Factory** and add it.
   * The native Teams **People** panel (roster icon in the header) is available automatically.

7. Grant microphone access when prompted by the browser.

#### Microphone in Teams Tabs

Teams tabs run inside an iframe. For microphone access to work:

* The manifest includes `"devicePermissions": ["media"]`, which tells Teams to add `allow="microphone"` to the iframe.
* The server sends a `Permissions-Policy: microphone=(self)` header so the browser permits the `getUserMedia` call.
* The app explicitly requests mic permission via `getUserMedia` before starting speech recognition, which triggers the browser permission prompt.

If the mic button shows "Microphone access denied," check that your browser has granted microphone permission to the Teams domain (or the dev tunnel domain when testing directly).

### npm Scripts

| Script                           | Description                                                           |
|----------------------------------|-----------------------------------------------------------------------|
| `npm start`                      | Build (server + Azure-Speech client) and start the server (port 3978) |
| `npm run start:voicelive`        | Build server + Voice Live client and start the server                 |
| `npm run start:webspeech`        | Build server + Web Speech client and start the server                 |
| `npm run build`                  | Compile server (tsc) and bundle client (esbuild, Azure default)       |
| `npm run build:voicelive`        | Compile server and bundle client with Voice Live                      |
| `npm run build:webspeech`        | Compile server and bundle client with Web Speech API                  |
| `npm run build:server`           | Compile server TypeScript only                                        |
| `npm run build:client`           | Bundle client with default speech provider (Azure)                    |
| `npm run build:client:webspeech` | Bundle client with browser Web Speech API                             |
| `npm run build:client:azure`     | Bundle client with Azure Speech SDK                                   |
| `npm run build:client:voicelive` | Bundle client with Voice Live (preview)                               |
| `npm run dev:server`             | Build server and start with `--watch` for auto-restart                |
| `npm run dev:client`             | Bundle client in watch mode (Azure Speech SDK)                        |
| `npm run dev:client:webspeech`   | Bundle client in watch mode (Web Speech API)                          |
| `npm run dev:client:voicelive`   | Bundle client in watch mode (Voice Live)                              |

### Known Limitations

* The Web Speech API provider (`npm run build:client:webspeech`) requires Chrome or Edge on desktop. The Teams desktop (Electron) client may not support it. The default Azure Speech SDK provider works across all platforms. The text input fallback works everywhere.
* Session storage is in-memory. All sessions and message history reset on server restart.
* The Foundry backend uses synchronous `createAndPoll`, which blocks the HTTP request until the agent finishes processing. The Copilot Studio Agents SDK backend streams tokens via `@microsoft/agents-copilotstudio-client`. The Direct Line backend is asynchronous (fire-and-forget POST + WebSocket relay).
* Express 5 uses different route syntax from Express 4 (for example, `/{*splat}` instead of `*` for wildcard routes).
* The native Teams People panel is only visible when the app is installed in a group chat or meeting context.

## Local Development (Docker Compose)

### Docker Compose Overview

Use Docker Compose for local development and smoke testing without a Kubernetes cluster.
The compose file builds the service image from
`services/chat-with-your-factory/Dockerfile`, loads configuration from `.env`,
and exposes port `3978`.

### Docker Compose Prerequisites

* Docker Engine with Compose v2
* Access to the repository workspace
* A valid `.env` file in the component root

### Docker Compose Quick Start

From `src/500-application/513-chat-with-your-factory/` run:

```bash
docker compose up --build
```

Open the app at:

```text
http://localhost:3978
```

Stop the stack:

```bash
docker compose down
```

### Docker Compose Configuration

The compose service reads:

* `.env` via `env_file`
* `SERVICE_PORT` for host port mapping (defaults to `3978`)
* `REGISTRY`, `APPLICATION`, and `BUILD_ID` for image naming

Common local development defaults:

* `SKIP_AUTH=true` for standalone mode
* `AGENT_BACKEND=copilotstudio` or `foundry` based on your environment

### Common Commands

Rebuild after source changes:

```bash
docker compose up --build --force-recreate
```

View logs:

```bash
docker compose logs -f chat-with-your-factory
```

Remove containers, network, and local anonymous volumes:

```bash
docker compose down -v
```

### Docker Compose Troubleshooting

#### Port already in use

If `3978` is in use, set another host port:

```bash
SERVICE_PORT=4078 docker compose up --build
```

#### App starts but requests fail with 401

For local standalone development, confirm `.env` includes one of:

* `SKIP_AUTH=true`
* `AUTH_REQUIRED=false`

#### Build fails at TypeScript or esbuild step

Ensure required files exist in the service directory:

* `tsconfig.json`
* `tsconfig.server.json`
* `src/client/index.tsx`
* `src/server/index.ts`

#### Environment values not applied

Regenerate `.env` from defaults if needed:

```bash
./scripts/generate-env-config.sh
```

## Kubernetes Deployment (Helm)

### Helm Overview

The Helm chart in `charts/chat-with-your-factory/` deploys Chat With Factory to a
Kubernetes cluster with:

* Deployment (`apps/v1`)
* Service (`ClusterIP`)
* ConfigMap for non-secret environment values

Use this guide for cluster deployments after image build and push.

### Helm Prerequisites

* Kubernetes cluster access (`kubectl` configured)
* Helm 3
* Container image available in ACR or another registry
* Namespace create permissions

### Chart Layout

```text
charts/chat-with-your-factory/
  Chart.yaml
  values.yaml
  templates/
    _helpers.tpl
    deployment.yaml
    service.yaml
    configmap.yaml
```

### Configure Values

Update or override these keys from `values.yaml`:

* `image.repository`
* `image.tag`
* `service.port` and `service.targetPort`
* `resources.requests` and `resources.limits`
* `env` map for runtime, non-secret settings

> [!IMPORTANT]
> Do not place secrets in `values.yaml` or ConfigMap-backed `env` values. Use
> Kubernetes Secrets and reference them from the deployment.

### Deploy

Create the dedicated namespace first (or rely on `--create-namespace` in the command below):

```bash
kubectl create namespace chat-with-your-factory
```

From `src/500-application/513-chat-with-your-factory/` run:

```bash
helm upgrade --install chat-with-your-factory ./charts/chat-with-your-factory \
  --namespace chat-with-your-factory \
  --create-namespace \
  --set image.repository=<registry>/chat-with-your-factory \
  --set image.tag=1.0.0
```

### Validate Deployment

Check release status:

```bash
helm status chat-with-your-factory --namespace chat-with-your-factory
```

Check pods and service:

```bash
kubectl get pods,svc -n default -l app.kubernetes.io/name=chat-with-your-factory
```

Render templates locally before deploy:

```bash
helm template chat-with-your-factory ./charts/chat-with-your-factory
```

### Upgrade and Rollback

Upgrade by changing image tag and re-running `helm upgrade --install`.

Rollback to previous revision:

```bash
helm rollback chat-with-your-factory 1 --namespace chat-with-your-factory
```

### Uninstall

```bash
helm uninstall chat-with-your-factory --namespace chat-with-your-factory
```

### Helm Troubleshooting

#### Helm install succeeds but pod does not become ready

Describe the pod and inspect events:

```bash
kubectl describe pod -n default <pod-name>
```

Check logs:

```bash
kubectl logs -n default <pod-name>
```

#### Image pull errors

Verify `image.repository`, `image.tag`, and pull secret:

* `imagePullSecrets[0].name` must exist in target namespace
* Registry credentials must grant pull access

#### App returns 401 in cluster

Confirm runtime auth configuration in chart values:

* Set `env.AUTH_REQUIRED="false"` only for non-production scenarios
* Keep `env.AUTH_REQUIRED="true"` for production with valid identity flow

## Session Sharing and Collaboration

The app supports bringing other people into an active agent session — useful for escalations, second opinions, or shift handovers.

### How it works

1. A user starts a conversation with the agent (e.g., diagnosing equipment issues).
2. When they need to bring someone else in, they click the **Add to session** button (person+ icon) in the session bar.
3. They enter the colleague's email address and click **Add**.
4. In Teams mode, a new group chat opens with that person and the Chat With Factory tab pre-installed.
5. Both users now have the tab in a shared group chat context, with the native Teams **People** panel available for roster management.

### Planned enhancements

* **Automatic session sync** — when a session is created in a group chat, all chat members are automatically added as session participants so everyone sees the same agent conversation and Foundry thread history.
* **SSO-based people picker** — when running in a same-tenant environment with SSO enabled, the Teams native people picker (`people.selectPeople()`) replaces the email input for a richer experience.
* **Real-time message push** — server-sent events (SSE) broadcast new agent responses to all session participants simultaneously.

## Project Structure

```text
services/chat-with-your-factory/src/
  server/
    index.ts              Express server, static files, shutdown hooks
    agentsClient.ts       Foundry SDK client initialization
    copilotStudioClient.ts Agents SDK client with OBO exchange and streaming
    directLineClient.ts   Direct Line conversation manager (WebSocket relay)
    chatHandler.ts        Conditional Foundry/Direct Line/CPS chat routing
    sessionsHandler.ts    Session CRUD with conditional backend init
    sessionStore.ts       In-memory session + message storage
    transcriptHandler.ts  Local transcript retrieval
    sseHandler.ts         Server-sent events for real-time message relay
    sseRegistry.ts        SSE broadcast infrastructure
    authMiddleware.ts     JWT validation via jose JWKS (v1.0 and v2.0 issuers)
    aclHelper.ts          Session participant access control
    express.d.ts          Express Request augmentation (req.user, req.ssoToken)
  client/
    index.tsx             React entry point
    App.tsx               Root component, conversation state, Teams SDK init
    utils/
      apiFetch.ts         fetch wrapper with auto-attached Bearer token
    hooks/
      useSpeech.ts              Barrel hook that selects speech provider at build time
      useAzureSpeech.ts         Azure Speech SDK hook (client-side, streams to Azure)
      useSpeechRecognition.ts   Web Speech API hook (in-browser, Chrome/Edge only)
      useSessionMessages.ts     SSE hook for real-time message subscription
      useTeamsTheme.ts          Maps Teams theme context to Fluent UI themes
      useTeamsUser.ts           Resolves user identity from Teams context + JWT
    components/
      ChatPanel.tsx             Scrollable message list with typing indicator
      VoiceInput.tsx            Mic toggle button with error feedback
      TextInput.tsx             Text input fallback for non-voice browsers
      SessionBar.tsx            Session selector and controls
      AddParticipantDialog.tsx  People picker via Teams SDK
  shared/
    types.ts              Session, TranscriptMessage, and UserContext interfaces
public/
  index.html              HTML shell
appManifest/
  manifest.json           Teams manifest v1.22 (gitignored, from template)
  manifest.TEMPLATE.json  Manifest template with placeholders
```
