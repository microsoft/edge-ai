---
title: Chat With Factory
description: A voice-enabled AI agent web application for industrial environments powered by Azure AI Foundry Agents or Copilot Studio
ms.date: 2026-04-29
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

# Chat With Factory

A web application that captures voice input, sends recognized text to an AI agent, and displays the conversation in a chat panel. Designed for hands-free access to AI-powered guidance in industrial environments. Runs standalone or optionally inside Microsoft Teams.

The app supports three configurable agent backends:

* **Copilot Studio via Agents SDK** (default) with OBO token exchange and streaming responses
* **Azure AI Foundry Agents** with synchronous `createAndPoll`
* **Copilot Studio via Direct Line API 3.0** with asynchronous WebSocket relay

Set `AGENT_BACKEND` in `.env` to `copilotstudio`, `foundry`, or `directline` to choose.

## Documentation

| Document | Description |
|----------|-------------|
| [Setup Guide](docs/setup-guide.md) | Azure resources, environment variables, Copilot Studio configuration |
| [Architecture](docs/architecture.md) | Architecture diagrams, technology stack, data flow, API routes |
| [Development Guide](docs/development.md) | Local testing, Teams testing, npm scripts, known limitations |

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

## Architecture Overview

See [Architecture](docs/architecture.md) for diagrams, technology stack, data flow, and API routes.

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

## Quick Start

1. Complete resource setup in the [Setup Guide](docs/setup-guide.md).
2. Install and run:

   ```bash
   npm install
   npm start
   ```

3. See the [Development Guide](docs/development.md) for local testing, Teams sideloading, and npm scripts.
