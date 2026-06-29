#!/bin/bash

# Generate Environment Configuration for Chat With Factory
# Creates a .env file with all required environment variables.
# Uses current environment variables as values, with defaults for unset variables.

set -e

CURRENT_DIR=$(dirname "$0")

FOUNDRY_ENDPOINT=${FOUNDRY_ENDPOINT:-<your-foundry-endpoint>}
FOUNDRY_AGENT_ID=${FOUNDRY_AGENT_ID:-<your-foundry-agent-id>}
FOUNDRY_MODEL_DEPLOYMENT=${FOUNDRY_MODEL_DEPLOYMENT:-<your-model-deployment-name>}
AZURE_TENANT_ID=${AZURE_TENANT_ID:-<your-tenant-id>}
AGENT_BACKEND=${AGENT_BACKEND:-foundry}

FABRIC_WORKSPACE_ID=${FABRIC_WORKSPACE_ID:-<your-fabric-workspace-id>}
FABRIC_LAKEHOUSE_ID=${FABRIC_LAKEHOUSE_ID:-<your-fabric-lakehouse-id>}
FABRIC_SQL_ENDPOINT=${FABRIC_SQL_ENDPOINT:-}
FABRIC_LAKEHOUSE_DATABASE=${FABRIC_LAKEHOUSE_DATABASE:-RoboticsOntologyLH}

CPS_ENVIRONMENT_ID=${CPS_ENVIRONMENT_ID:-<power-platform-environment-id>}
CPS_AGENT_IDENTIFIER=${CPS_AGENT_IDENTIFIER:-<copilot-schema-name>}

PORT=${PORT:-3978}
AUTH_REQUIRED=${AUTH_REQUIRED:-true}

TEAMS_APP_ID=${TEAMS_APP_ID:-<your-teams-app-id>}
TEAMS_AUTH_AUDIENCES=${TEAMS_AUTH_AUDIENCES:-<audience-1>,<audience-2>}

AZURE_SPEECH_REGION=${AZURE_SPEECH_REGION:-<your-speech-region>}
AZURE_SPEECH_RESOURCE_ID=${AZURE_SPEECH_RESOURCE_ID:-<your-speech-resource-name>}

VOICE_PROVIDER=${VOICE_PROVIDER:-azure}

cat <<EOF >"${CURRENT_DIR}"/../.env
# Azure AI Foundry Agent
FOUNDRY_ENDPOINT=${FOUNDRY_ENDPOINT}
FOUNDRY_AGENT_ID=${FOUNDRY_AGENT_ID}
FOUNDRY_MODEL_DEPLOYMENT=${FOUNDRY_MODEL_DEPLOYMENT}
AZURE_TENANT_ID=${AZURE_TENANT_ID}

# Agent backend: "foundry" (default), "copilotstudio", or "directline"
AGENT_BACKEND=${AGENT_BACKEND}

# Factory ontology tool (query_factory_ontology) - RoboticsOntologyLH lakehouse reads.
# Provide FABRIC_SQL_ENDPOINT or FABRIC_WORKSPACE_ID + FABRIC_LAKEHOUSE_ID.
# Backend identity needs lakehouse read (SQL scope https://database.windows.net/.default).
FABRIC_WORKSPACE_ID=${FABRIC_WORKSPACE_ID}
FABRIC_LAKEHOUSE_ID=${FABRIC_LAKEHOUSE_ID}
FABRIC_SQL_ENDPOINT=${FABRIC_SQL_ENDPOINT}
FABRIC_LAKEHOUSE_DATABASE=${FABRIC_LAKEHOUSE_DATABASE}

# Copilot Studio Agents SDK
CPS_ENVIRONMENT_ID=${CPS_ENVIRONMENT_ID}
CPS_AGENT_IDENTIFIER=${CPS_AGENT_IDENTIFIER}

# Server
PORT=${PORT}

# Auth control
AUTH_REQUIRED=${AUTH_REQUIRED}

# Teams SSO authentication
TEAMS_APP_ID=${TEAMS_APP_ID}
TEAMS_AUTH_AUDIENCES=${TEAMS_AUTH_AUDIENCES}

# Azure Speech Services
AZURE_SPEECH_REGION=${AZURE_SPEECH_REGION}
AZURE_SPEECH_RESOURCE_ID=${AZURE_SPEECH_RESOURCE_ID}

# Voice provider: "azure", "webspeech", or "voicelive"
VOICE_PROVIDER=${VOICE_PROVIDER}
EOF

echo "Generated .env at ${CURRENT_DIR}/../.env"
