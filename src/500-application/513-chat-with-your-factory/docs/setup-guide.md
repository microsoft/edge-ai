---
title: Setup Guide
description: Azure resource setup, environment configuration, and Copilot Studio Direct Line integration for the Voice Agent Tab
ms.date: 2026-04-15
ms.topic: how-to
---

## Prerequisites

* [Node.js](https://nodejs.org/) v21 or later
* Azure CLI authenticated (`az login`)
* [Dev tunnels CLI](https://learn.microsoft.com/azure/developer/dev-tunnels/get-started) (`devtunnel`) for Teams testing
* Teams Developer Portal access (for sideloading)
* One of the following agent backends:
  * A published Copilot Studio agent with Agents SDK access (`AGENT_BACKEND=copilotstudio`, default)
  * An Azure AI Foundry project with a deployed agent (`AGENT_BACKEND=foundry`)
  * A published Copilot Studio agent with a web channel secret (`AGENT_BACKEND=directline`)

## Azure Resource Setup

Create the resources in order. All steps use Azure CLI and PowerShell.

```powershell
az login
devtunnel user login
```

### 1. Dev Tunnel

Create the tunnel first because the Entra app registration needs the hostname. You only run `devtunnel create` once. After that, rehost the same tunnel to keep a stable hostname.

```powershell
# One-time setup: create a persistent tunnel and add port 3978
devtunnel create --allow-anonymous
devtunnel port create -p 3978
```

Note the tunnel ID from the output (for example, `amusing-fog-wskvf9k`). The hostname follows the pattern `<tunnel-id>-3978.use.devtunnels.ms`.

```powershell
# Every time you develop: rehost the existing tunnel (hostname stays the same)
devtunnel host <tunnel-id>
```

Set the hostname variable in a separate terminal for the remaining steps:

```powershell
$TUNNEL_HOST = "<tunnel-id>-3978.use.devtunnels.ms"   # e.g. amusing-fog-wskvf9k-3978.use.devtunnels.ms
```

> [!TIP]
> Run `devtunnel host` in a separate terminal. It must stay running while you test in Teams. Use `devtunnel list` to see all your existing tunnels if you forget the ID.

### 2. Entra ID App Registration (Teams SSO)

Create the app registration, expose the `access_as_user` scope, and authorize Teams clients.

```powershell
# Create the registration with User.Read permission
az ad app create `
  --display-name "voice-agent-tab-sso" `
  --sign-in-audience AzureADMyOrg `
  --enable-id-token-issuance true `
  --requested-access-token-version 2 `
  --required-resource-accesses '[{\"resourceAppId\":\"00000003-0000-0000-c000-000000000000\",\"resourceAccess\":[{\"id\":\"e1fe6dd8-ba31-4d61-89e7-88639da4683d\",\"type\":\"Scope\"}]}]'

# Capture the IDs
$CLIENT_ID = az ad app list --display-name "voice-agent-tab-sso" --query "[0].appId" -o tsv
$OBJECT_ID = az ad app list --display-name "voice-agent-tab-sso" --query "[0].id" -o tsv
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
      adminConsentDescription = "Allow Teams to access the voice agent APIs as the signed-in user"
      adminConsentDisplayName = "Access as user"
      id                      = $SCOPE_ID
      isEnabled               = $true
      type                    = "User"
      userConsentDescription  = "Allow Teams to call voice agent APIs on your behalf"
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
      adminConsentDescription = "Allow Teams to access the voice agent APIs as the signed-in user"
      adminConsentDisplayName = "Access as user"
      id                      = $SCOPE_ID
      isEnabled               = $true
      type                    = "User"
      userConsentDescription  = "Allow Teams to call voice agent APIs on your behalf"
      userConsentDisplayName  = "Access as user"
      value                   = "access_as_user"
    })
    preAuthorizedApplications = @(
      @{ appId = "1fec8e78-bce4-4aaf-ab1b-5451cc387264"; delegatedPermissionIds = @($SCOPE_ID) }
      @{ appId = "5e3ce6c0-2b1f-4285-8d4b-75ee78787346"; delegatedPermissionIds = @($SCOPE_ID) }
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
  --api $(az ad sp show --id "00000003-0000-0000-c000-000000000000" --query id -o tsv) `
  --scope "User.Read"
```

> [!TIP]
> If this fails with "Insufficient privileges," you can skip it. The `User.Read` permission was already declared on the app during creation. Users see a one-time consent prompt instead. Alternatively, ask a tenant admin to grant consent in Azure Portal > App registrations > API permissions > Grant admin consent.

Print the values you need for configuration:

```powershell
Write-Host "TEAMS_APP_ID=$CLIENT_ID"
Write-Host "AZURE_TENANT_ID=$TENANT_ID"
```

### 3. Azure AI Foundry Project

> [!NOTE]
> Only required when using the Foundry backend (`AGENT_BACKEND=foundry` or unset). Skip to [Copilot Studio (Direct Line)](#4-copilot-studio-direct-line) if using Direct Line.

Create the Foundry resource, project, and model deployment:

```powershell
$RG_NAME   = "rg-voice-agent"
$LOCATION  = "eastus"
$AI_NAME   = "voice-agent-ai"
$PROJECT   = "voice-agent-project"

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

### 4. Copilot Studio (Direct Line)

> [!NOTE]
> Only required when using the Direct Line backend (`AGENT_BACKEND=directline`). Skip this if using Foundry or Agents SDK.

The Direct Line backend connects to a Copilot Studio agent via the Direct Line API 3.0. The server holds the channel secret and proxies all messages through a WebSocket relay.

#### Create and configure the Copilot Studio agent

1. Go to [Copilot Studio](https://copilotstudio.microsoft.com/) and create or open your agent.
2. Configure the agent's topics, knowledge sources, and authentication as needed.
3. **Publish** the agent (required; unpublished agents return `LatestPublishedVersionNotFound`).

#### Get the web channel secret

1. In Copilot Studio, go to **Settings** > **Channels** > **Custom website**.
2. Copy either **Secret 1** or **Secret 2** (two secrets are provided for zero-downtime rotation).
3. Set `DIRECT_LINE_SECRET` in your `.env` to the copied secret.

#### Configure the environment

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

#### Verify the connection

```bash
npm start
```

Open the app (localhost or via dev tunnel). Create a session; the server logs `[DirectLine] WebSocket connected for session ...` on success. Send a message and verify the agent responds via SSE.

#### Troubleshooting

| Error                               | Cause                                  | Fix                                                               |
|-------------------------------------|----------------------------------------|-------------------------------------------------------------------|
| `LatestPublishedVersionNotFound`    | Agent not published                    | Publish the agent in Copilot Studio                               |
| `AuthenticationNotConfigured`       | Agent's knowledge source auth missing  | Configure authentication in Copilot Studio Settings > Security    |
| `Failed to start Direct Line conversation: 403` | Invalid or expired secret     | Copy a fresh secret from Copilot Studio Channels > Custom website |
| `DIRECT_LINE_SECRET is required`    | Env var missing                        | Add `DIRECT_LINE_SECRET` to `.env`                                |

### 5. Copilot Studio (Agents SDK)

> [!NOTE]
> Only required when using the Agents SDK backend (`AGENT_BACKEND=copilotstudio`, the default). Skip this if using Foundry or Direct Line.

The Agents SDK backend connects to a Copilot Studio agent using `@microsoft/agents-copilotstudio-client` with OBO (On-Behalf-Of) token exchange. The server exchanges the Teams SSO token for a Power Platform token via MSAL.

#### App registration: add a client secret

1. In Azure Portal, go to **App registrations** > your voice-agent-tab registration.
2. Under **Certificates & secrets** > **Client secrets**, click **New client secret**.
3. Copy the secret value and set `TEAMS_APP_CLIENT_SECRET` in your `.env`.

#### App registration: add Power Platform API consent

1. In Azure Portal, go to **App registrations** > your app > **API permissions**.
2. Click **Add a permission** > **APIs my organization uses**.
3. Search for **Power Platform API** (app ID `8578e004-a5c6-46e7-913e-12f58912df43`). If it does not appear, create the service principal first:

   ```powershell
   az ad sp create --id 8578e004-a5c6-46e7-913e-12f58912df43
   ```

4. Select **Delegated permissions**, check the default scope, and click **Add permissions**.
5. Click **Grant admin consent** (requires Global Admin or Privileged Role Administrator).

#### Find your CPS_ENVIRONMENT_ID

Open [Copilot Studio](https://copilotstudio.microsoft.com/) and select your agent. The environment ID is in the URL:

```text
https://copilotstudio.microsoft.com/environments/<ENVIRONMENT_ID>/agents/...
```

#### Find your CPS_AGENT_IDENTIFIER

1. In [Power Apps](https://make.powerapps.com/), go to **Solutions** > **Default Solution**.
2. Filter by **Copilot** type and find your agent.
3. The **Name** column shows the schema name (for example, `crd49_MIKEBOT`). Use this as `CPS_AGENT_IDENTIFIER`.

#### Find your CPS_DIRECT_CONNECT_URL (optional)

If you prefer to use the direct connect URL instead of environment ID and agent identifier:

1. In Copilot Studio, go to **Settings** > **Channels** > **Web app**.
2. Copy the **Direct connect URL**.
3. Set `CPS_DIRECT_CONNECT_URL` in your `.env`. When set, this overrides `CPS_ENVIRONMENT_ID` and `CPS_AGENT_IDENTIFIER`.

#### Configure the environment

Set these variables in `.env`:

```bash
AGENT_BACKEND=copilotstudio
CPS_ENVIRONMENT_ID=<power-platform-environment-id>
CPS_AGENT_IDENTIFIER=<copilot-schema-name>
TEAMS_APP_CLIENT_SECRET=<client-secret-from-app-registration>
```

#### Verify the connection

```bash
npm start
```

Open the app in Teams (OBO exchange requires a real Teams SSO token; `SKIP_AUTH=true` does not work with this backend). Create a session and send a message. The server logs `[CopilotStudio] Streaming reply for session ...` on success.

## Configuration Files

> [!NOTE]
> The app supports three agent backends. Set `AGENT_BACKEND` in `.env` to choose which one to use.
> Copilot Studio Agents SDK variables (`CPS_ENVIRONMENT_ID`, `CPS_AGENT_IDENTIFIER`, `TEAMS_APP_CLIENT_SECRET`) are only required when `AGENT_BACKEND=copilotstudio` (the default).
> Foundry-specific variables (`FOUNDRY_ENDPOINT`, `FOUNDRY_AGENT_ID`) are only required when `AGENT_BACKEND=foundry`.
> Direct Line variables (`DIRECT_LINE_SECRET`) are only required when `AGENT_BACKEND=directline`.

### Environment variables (`.env`)

Copy from `env.TEMPLATE` if the file does not exist.

| Variable              | Required     | Description                                                  |
|-----------------------|--------------|--------------------------------------------------------------|
| `FOUNDRY_ENDPOINT`    | Foundry only | Azure AI Foundry project endpoint                            |
| `FOUNDRY_AGENT_ID`    | Foundry only | Foundry agent/assistant ID                                   |
| `AZURE_TENANT_ID`     | Yes          | Entra ID tenant                                              |
| `TEAMS_APP_ID`        | Yes          | Entra app registration client ID                             |
| `DEVTUNNEL_DOMAIN`    | Teams dev    | Dev tunnel hostname, e.g. `abc123-3978.use.devtunnels.ms`    |
| `AGENT_BACKEND`       | No           | `copilotstudio`, `directline`, or `foundry` (default: `copilotstudio`) |
| `DIRECT_LINE_SECRET`  | DL only      | Copilot Studio web channel secret                            |
| `DIRECT_LINE_ENDPOINT`| No           | Regional DL endpoint (default: `directline.botframework.com`)|
| `CPS_ENVIRONMENT_ID`  | CPS only     | Power Platform environment ID                                |
| `CPS_AGENT_IDENTIFIER`| CPS only     | Copilot agent schema name (e.g., `crd49_MIKEBOT`)            |
| `CPS_DIRECT_CONNECT_URL` | No        | Direct connect URL from Copilot Studio Channels > Web app (overrides `CPS_ENVIRONMENT_ID` and `CPS_AGENT_IDENTIFIER`) |
| `TEAMS_APP_CLIENT_SECRET` | CPS only  | Client secret from app registration (for OBO exchange)       |
| `PORT`                | No           | Server port (default: `3978`)                                |
| `SKIP_AUTH`           | No           | Set `true` for local dev without Teams                       |
| `AZURE_SPEECH_REGION` | Speech only  | Azure Speech Services region                                 |
| `AZURE_SPEECH_RESOURCE_ID` | Speech only | Azure Speech resource name                              |

### Teams manifest (`appManifest/manifest.json`)

Copy from `manifest.TEMPLATE.json` and fill in:

| Field                          | Value                                     |
|--------------------------------|-------------------------------------------|
| `id`                           | A new GUID (`[guid]::NewGuid()`)          |
| `staticTabs[0].contentUrl`     | `https://<tunnel-hostname>`               |
| `validDomains[0]`              | `<tunnel-hostname>`                       |
| `webApplicationInfo.id`        | `$CLIENT_ID`                              |
| `webApplicationInfo.resource`  | `api://<tunnel-hostname>/$CLIENT_ID`      |

### Switching Tenants or Subscriptions

When moving to a new tenant or subscription, repeat the steps above and re-authenticate:

```powershell
az login --tenant <new-tenant-id>
```

All Foundry API calls use `DefaultAzureCredential`, which picks up the active `az login` session.
