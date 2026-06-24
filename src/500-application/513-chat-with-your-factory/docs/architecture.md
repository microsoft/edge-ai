---
title: Architecture
description: Architecture overview, technology stack, data flow, and API routes for Chat With Factory
ms.date: 2026-04-15
ms.topic: concept
---

## Architecture Overview

### Current (Prototype)

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

### MVP Architecture

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

## Technology Stack

Each concern maps to a specific technology. No component serves double duty. The **MVP Upgrade** column shows what each component needs to reach production quality.

| Concern                   | Technology                                                                       | Details                                                                                                                                                                                                                                                                                                                                                                | MVP Upgrade                                                                                                                                          |
|---------------------------|----------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| Speech-to-text (STT)      | Configurable: Azure Speech SDK (default) or Browser Web Speech API or Voice Live | Build-time switch via `npm run build:client:azure`, `npm run build:client:webspeech`, or `npm run build:client:voicelive`. esbuild tree-shakes the unused providers at build time. Voice Live (`VOICE_PROVIDER=voicelive`) uses a server-proxied WebSocket bridge at `/api/voice-live` — see [ADR 0001](../../docs/adr/0001-adopt-voice-live-as-stt-tts-front-end.md). | Server-side real-time STT via Azure Speech SDK. Browser streams raw audio to Express server via WebSocket; server runs Speech SDK for transcription. |
| Text-to-speech (TTS)      | None today                                                                       | Voice Live can produce TTS in principle, but the current bridge runs it as STT/VAD only (`modalities: ['text']`, `create_response: false`) — see [ADR 0001](../../docs/adr/0001-adopt-voice-live-as-stt-tts-front-end.md). Agent responses render as text in all configurations.                                                                                       | Azure Speech neural TTS for optional read-aloud via `/api/tts` endpoint, or enable Voice Live audio output once topology supports it.                |
| AI / LLM backend          | Copilot Studio (Agents SDK), Azure AI Foundry, or Copilot Studio (Direct Line)   | Configurable via `AGENT_BACKEND` env var (`copilotstudio` default). Agents SDK uses `@microsoft/agents-copilotstudio-client` with OBO token exchange and streaming. Foundry uses Assistants-style threads with `createAndPoll`. Direct Line uses fire-and-forget POST with WebSocket relay for bot replies.                                                            | Foundry streaming via `createAndStream` + SSE for real-time token delivery.                                                                          |
| Server framework          | Express v5 (TypeScript, ESM)                                                     | Serves static files, REST API routes, SSE broadcast, and `Permissions-Policy` header for iframe microphone access.                                                                                                                                                                                                                                                     | Same. Native async error handling. Managed Identity via `DefaultAzureCredential` in production.                                                      |
| User authentication       | Teams SSO + JWT validation (`jose`)                                              | Validates AAD v2.0 tokens. Dev bypass via `SKIP_AUTH=true`.                                                                                                                                                                                                                                                                                                            | Remove `SKIP_AUTH` bypass in production.                                                                                                             |
| Session storage (hot)     | In-memory `Map<string, Session>`                                                 | All sessions reset on server restart.                                                                                                                                                                                                                                                                                                                                  | Azure Cache for Redis (Basic C0) with 30-day TTL.                                                                                                    |
| Session storage (durable) | None                                                                             | Sessions lost on restart.                                                                                                                                                                                                                                                                                                                                              | Azure Blob Storage as system of record + Azure AI Search as query layer.                                                                             |
| Collaboration             | Teams JS SDK v2 people picker + deep links                                       | Native Teams people picker for adding collaborators. Deep links open group chats with the tab pre-installed.                                                                                                                                                                                                                                                           | Automatic session sync via Graph API. SSE push for real-time updates.                                                                                |
| Hosting and secrets       | localhost + dev tunnels; `.env` file                                             | Local development only.                                                                                                                                                                                                                                                                                                                                                | Azure App Service + Key Vault references.                                                                                                            |
| Observability             | `console.log` / `console.error`                                                  | No structured telemetry.                                                                                                                                                                                                                                                                                                                                               | Azure Application Insights with distributed tracing.                                                                                                 |

## Data Flow

A single user interaction follows this path:

1. The user clicks the mic button or types a message.
2. For voice: the `useSpeech` barrel hook delegates to either the Web Speech API, Azure Speech SDK, or Voice Live hook based on the build-time `__SPEECH_PROVIDER__` constant.
3. For Web Speech and Azure Speech providers, the React client sends a POST to `/api/chat` with the message text. For Voice Live, the browser sends raw PCM16 audio over a WebSocket to `/api/voice-live`; the server bridge handles transcription and agent dispatch (via `dispatchChat`) — no `/api/chat` POST is made for voice turns. Agent responses arrive via SSE and render as text (no TTS playback today).
4. The Express server validates the JWT, checks the user's session ACL, stores the user message locally, and broadcasts it via SSE.
5. **Copilot Studio (Agents SDK) backend**: The server performs an OBO token exchange using MSAL, connects to the Copilot Studio agent via `@microsoft/agents-copilotstudio-client`, streams the response, stores it locally, broadcasts via SSE, and returns it in the HTTP response.
6. **Foundry backend**: The server forwards the message to the Foundry agent via `agentsClient.messages.create`, calls `createAndPoll`, retrieves the response, stores it locally, broadcasts via SSE, and returns it in the HTTP response.
7. **Direct Line backend**: The server sends the message to Copilot Studio via Direct Line POST (fire-and-forget) and returns immediately. The bot's reply arrives via WebSocket, gets stored locally, and is broadcast to the client via SSE.
8. The React client displays the response in the chat panel (from either the HTTP response body or SSE event).

## API Routes

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
