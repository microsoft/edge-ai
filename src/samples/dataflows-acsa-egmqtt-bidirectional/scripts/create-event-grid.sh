#!/bin/bash

# shellcheck disable=SC1091
source ./utils/common.sh

echo "Checking if required environment variables are set and setting defaults if not"
check_env_var "RESOURCE_GROUP"
check_env_var "CLUSTER_NAME"
check_env_var "LOCATION"
EVENT_GRID_NAMESPACE_NAME=${EVENT_GRID_NAMESPACE_NAME:-"eg-$RESOURCE_GROUP"}
METRIC1_TOPIC_PATH_NAME=${METRIC1_TOPIC_PATH_NAME:-"machine-status"}
METRIC2_TOPIC_PATH_NAME=${METRIC2_TOPIC_PATH_NAME:-"total-counter"}
METRIC3_TOPIC_TEMPLATE_NAME=${METRIC3_TOPIC_TEMPLATE_NAME:-"devices-health"}

verify_azcli_installed
navigate_to_scripts_dir

topicSpaceName="metrics"

az config set --local extension.use_dynamic_install=yes_without_prompt

# Create an Event Grid namespace with MQTT broker enabled
# Note that 'eventGridMaxClientSessionsPerAuthName' parameter should be increased if more Event Grid sync dataflows are created
eventGridMaxClientSessionsPerAuthName=${EVENT_GRID_MAX_CLIENT_SESSIONS:-10}
az eventgrid namespace create --namespace-name "$EVENT_GRID_NAMESPACE_NAME" --resource-group "$RESOURCE_GROUP" --location "$LOCATION" --topic-spaces-configuration "{state:Enabled,maximumClientSessionsPerAuthenticationName:$eventGridMaxClientSessionsPerAuthName}"

# Create a topic space within the namespace
echo "Creating topic space $topicSpaceName within Event Grid namespace $EVENT_GRID_NAMESPACE_NAME..."
az eventgrid namespace topic-space create --resource-group "$RESOURCE_GROUP" --namespace-name "$EVENT_GRID_NAMESPACE_NAME" --name "$topicSpaceName" --topic-templates "[\"$METRIC1_TOPIC_PATH_NAME\", \"$METRIC3_TOPIC_TEMPLATE_NAME\", \"$METRIC2_TOPIC_PATH_NAME\"]"

echo "Event Grid namespace $EVENT_GRID_NAMESPACE_NAME and topic space $topicSpaceName created."

# Get aio extension name
echo "Getting the name of the Azure IoT Operations extension..."
aioExtensionName=$(az k8s-extension list --resource-group "$RESOURCE_GROUP" --cluster-name "$CLUSTER_NAME" --cluster-type connectedClusters --query "[?extensionType=='microsoft.iotoperations'].name" -o tsv)

# Get principal ID
echo "Getting the principal ID of the Azure IoT Operations extension..."
principalId=$(az k8s-extension show \
  --resource-group "$RESOURCE_GROUP" \
  --cluster-name "$CLUSTER_NAME" \
  --name "$aioExtensionName" \
  --cluster-type connectedClusters \
  --query identity.principalId -o tsv)

subscriptionId=$(az account show --query id --output tsv)

# Assign publisher and subscriber roles to MQTT broker
echo "Assigning the EventGrid TopicSpaces Publisher role to the Azure IoT Operations extension principal..."

az role assignment create \
  --assignee "$principalId" \
  --role "EventGrid TopicSpaces Publisher" \
  --scope /subscriptions/"$subscriptionId"/resourceGroups/"$RESOURCE_GROUP"/providers/Microsoft.EventGrid/namespaces/"$EVENT_GRID_NAMESPACE_NAME"/topicSpaces/"$topicSpaceName"

echo "Assigning the EventGrid TopicSpaces Subscriber role to the Azure IoT Operations extension principal..."

az role assignment create \
  --assignee "$principalId" \
  --role "EventGrid TopicSpaces Subscriber" \
  --scope /subscriptions/"$subscriptionId"/resourceGroups/"$RESOURCE_GROUP"/providers/Microsoft.EventGrid/namespaces/"$EVENT_GRID_NAMESPACE_NAME"/topicSpaces/"$topicSpaceName"
