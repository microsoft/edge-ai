# 045-Notification — Bicep

This directory is a **staged upstream patch** for the edge-ai repository at `https://dev.azure.com/ai-at-the-edge-flagship-accelerator/_git/edge-ai`. It adds the Bicep flavor of the `000-cloud/045-notification` module — only the Terraform flavor exists upstream today.

## Upstream PR procedure

1. Clone the upstream edge-ai repository
2. Copy this directory into place:

   ```bash
   cp -r contrib/upstream-patches/045-notification/bicep \
         <edge-ai-clone>/src/000-cloud/045-notification/bicep
   ```

3. Add a README matching the sibling 040-messaging module's style
4. Run `bicep build src/000-cloud/045-notification/bicep/main.bicep` from the upstream clone to confirm it still compiles in that repo's context
5. Open a PR into upstream `main`
6. Once merged, remove this staged copy from `contrib/upstream-patches/` in the leak-detection-accelerator repository

## Module overview

Deploys two Azure Logic App workflows and supporting API connections:

- **Primary workflow** (`la-<prefix>-leak-notify-<env>-<instance>`) subscribes to `ALERT_DLQC` events on Event Hub, deduplicates via an Azure Table (`leaksessions`), and posts new-leak alerts to Microsoft Teams.
- **Close workflow** (`la-<prefix>-leak-close-<env>-<instance>`) exposes an HTTP endpoint. Clicking the "Close Leak" link in a Teams alert invokes this endpoint, which deletes the leak-session row and posts a closure summary.

## Post-deployment manual step

The Teams API connection requires **user consent** via the Azure Portal before Logic Apps can post to Teams:

1. Navigate to the deployed `apicon-teams-<prefix>-<env>-<instance>` connection
2. Click **Edit API connection**
3. Click **Authorize**
4. Save

Without this, the Teams actions in both workflows will fail at runtime.

## Parameters

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `common` | `core.Common` | yes | — | Standard settings: resourcePrefix, location, environment, instance |
| `resourceGroup` | `ResourceGroupRef` | yes | — | RG reference (name, id, location) |
| `eventhubNamespace` | `EventHubNamespaceRef` | yes | — | EH namespace reference (id, name) |
| `eventhubName` | `string` | yes | — | Name of the EH to subscribe to |
| `storageAccount` | `StorageAccountRef` | yes | — | Storage account reference (id, name) |
| `teamsRecipientId` | `string` | yes | — | Teams chat/channel thread ID |
| `shouldAssignRoles` | `bool` | no | `true` | Create role assignments for managed identities |
| `teamsPostLocation` | `string` | no | `'Group chat'` | Teams posting location type |
| `tags` | `object` | no | `{}` | Additional tags |
| `telemetry_opt_out` | `bool` | no | `false` | Opt out of telemetry deployment marker |

## Outputs

| Output | Type | Description |
|---|---|---|
| `closeLeakEndpoint` | `string` | HTTP URL of the close-leak trigger (embed in your Teams alerts) |
| `logicApp` | `LogicAppRef` | `{ id, name, identityPrincipalId }` of the notification workflow |
