---
title: Development Guide
description: Local development, Teams testing, npm scripts, and known limitations for Chat With Factory
ms.date: 2026-04-15
ms.topic: how-to
---

## Quick Start

1. Install dependencies:

   ```bash
   npm install
   ```

2. Copy the environment template and fill in your values (see [Setup Guide](setup-guide.md) for details):

   ```bash
   cp .env.template .env
   ```

3. Build and start the server:

   ```bash
   npm start
   ```

   This runs `npm run build` (TypeScript server compilation + esbuild client bundle) then starts the Express server on port 3978.

## Local Testing (Without Teams)

1. Set `SKIP_AUTH=true` in your `.env` file to bypass JWT validation.
2. Open `http://localhost:3978` in Chrome or Edge.
3. Click the mic button and speak, or type a message.
4. The agent response appears in the chat panel.

> [!TIP]
> The default speech provider (Azure Speech SDK) works across all browsers. To use the browser Web Speech API instead (Chrome/Edge only), run `npm run start:webspeech`. To use Voice Live (preview), set `VOICE_PROVIDER=voicelive` and `AZURE_VOICELIVE_RESOURCE` in `.env`, then run `npm run start:voicelive`. See [ADR 0001](../../docs/adr/0001-adopt-voice-live-as-stt-tts-front-end.md) for details. The text input fallback is always available.
>
> Plain `npm start` always rebuilds the client with the **default Azure Speech SDK** provider, which will overwrite any voicelive / webspeech bundle you previously built. Use `npm run start:voicelive` or `npm run start:webspeech` to keep the matching client bundle in sync with the server in one step.

## Testing in Teams

1. Start a dev tunnel:

   ```bash
   devtunnel host -p 3978 --allow-anonymous
   ```

   Note the tunnel hostname (for example, `abc123.usw2.devtunnels.ms`).

2. Update `appManifest/manifest.json` (see [Setup Guide](setup-guide.md#teams-manifest-appmanifestmanifestjson) for field mappings).

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

### Microphone in Teams Tabs

Teams tabs run inside an iframe. For microphone access to work:

* The manifest includes `"devicePermissions": ["media"]`, which tells Teams to add `allow="microphone"` to the iframe.
* The server sends a `Permissions-Policy: microphone=(self)` header so the browser permits the `getUserMedia` call.
* The app explicitly requests mic permission via `getUserMedia` before starting speech recognition, which triggers the browser permission prompt.

If the mic button shows "Microphone access denied," check that your browser has granted microphone permission to the Teams domain (or the dev tunnel domain when testing directly).

## npm Scripts

| Script                          | Description                                             |
|---------------------------------|---------------------------------------------------------|
| `npm start`                     | Build (server + Azure-Speech client) and start the server (port 3978) |
| `npm run start:voicelive`       | Build server + Voice Live client and start the server   |
| `npm run start:webspeech`       | Build server + Web Speech client and start the server   |
| `npm run build`                 | Compile server (tsc) and bundle client (esbuild, Azure default) |
| `npm run build:voicelive`       | Compile server and bundle client with Voice Live        |
| `npm run build:webspeech`       | Compile server and bundle client with Web Speech API    |
| `npm run build:server`          | Compile server TypeScript only                          |
| `npm run build:client`          | Bundle client with default speech provider (Azure)      |
| `npm run build:client:webspeech`| Bundle client with browser Web Speech API               |
| `npm run build:client:azure`    | Bundle client with Azure Speech SDK                     |
| `npm run build:client:voicelive`| Bundle client with Voice Live (preview)                 |
| `npm run dev:server`            | Build server and start with `--watch` for auto-restart  |
| `npm run dev:client`            | Bundle client in watch mode (Azure Speech SDK)          |
| `npm run dev:client:webspeech`  | Bundle client in watch mode (Web Speech API)            |
| `npm run dev:client:voicelive`  | Bundle client in watch mode (Voice Live)                |

## Known Limitations

* The Web Speech API provider (`npm run build:client:webspeech`) requires Chrome or Edge on desktop. The Teams desktop (Electron) client may not support it. The default Azure Speech SDK provider works across all platforms. The text input fallback works everywhere.
* Session storage is in-memory. All sessions and message history reset on server restart.
* The Foundry backend uses synchronous `createAndPoll`, which blocks the HTTP request until the agent finishes processing. The Copilot Studio Agents SDK backend streams tokens via `@microsoft/agents-copilotstudio-client`. The Direct Line backend is asynchronous (fire-and-forget POST + WebSocket relay).
* Express 5 uses different route syntax from Express 4 (for example, `/{*splat}` instead of `*` for wildcard routes).
* The native Teams People panel is only visible when the app is installed in a group chat or meeting context.
