#!/bin/bash

set -e

# shellcheck disable=SC1091
source ./utils/common.sh

replace_placeholders_in_template_and_apply() {
    local templatePathName="$1"
    local uniquePostfix="$2"
    local endpointName="$3"
    local dataSource="$4"
    local dataDestination="$5"

    # Export variables for envsubst
    export UNIQUE_POSTFIX=$uniquePostfix
    export ENDPOINT_NAME=$endpointName
    export DATA_SOURCE=$dataSource
    export DATA_DESTINATION=$dataDestination

    # Apply the template using envsubst
    apply_template_with_envsubst "../yaml/${templatePathName}.yaml" | kubectl apply -f -
}

verify_kubectl_installed
verify_envsubst_installed
test_kubeapi_connection_with_retry
navigate_to_scripts_dir

echo "Checking if required environment variables are set and setting defaults if not"
check_env_var "RESOURCE_GROUP"
check_env_var "LOCATION"
ACSA_UNBACKED_AIO_PVC_NAME=${ACSA_UNBACKED_AIO_PVC_NAME:-"pvc-acsa-unbacked-aio"}
ACSA_CLOUD_BACKED_AIO_PVC_NAME=${ACSA_CLOUD_BACKED_AIO_PVC_NAME:-"pvc-acsa-cloud-backed-aio"}
EVENT_GRID_NAMESPACE_NAME=${EVENT_GRID_NAMESPACE_NAME:-"eg-$RESOURCE_GROUP"}
METRIC1_TOPIC_PATH_NAME=${METRIC1_TOPIC_PATH_NAME:-"machine-status"}
METRIC2_TOPIC_PATH_NAME=${METRIC2_TOPIC_PATH_NAME:-"total-counter"}
METRIC3_TOPIC_TEMPLATE_NAME=${METRIC3_TOPIC_TEMPLATE_NAME:-"devices-health"}

navigate_to_scripts_dir

# Dataflows profile creation
kubectl apply -f ../yaml/profiles/df-profile.yaml

# MQTT to file storage dataflows
## Endpoints creation
acsaUnbackedEndpointName="acsa-unbacked"
acsaCloudBackedEndpointName="acsa-cloud-backed"

# Export variables for unbacked endpoint
export PVC_NAME=$ACSA_UNBACKED_AIO_PVC_NAME
export ENDPOINT_NAME=$acsaUnbackedEndpointName
# Apply the template using envsubst
apply_template_with_envsubst "../yaml/endpoints/acsa-df-endpoint.yaml" | kubectl apply -f -

# Export variables for cloud-backed endpoint
export PVC_NAME=$ACSA_CLOUD_BACKED_AIO_PVC_NAME
export ENDPOINT_NAME=$acsaCloudBackedEndpointName
# Apply the template using envsubst
apply_template_with_envsubst "../yaml/endpoints/acsa-df-endpoint.yaml" | kubectl apply -f -

## Dataflows creation
mqttFileSystemTemplate="mqtt-file-system/mqtt-to-file-system-df"
echo "Applying the MQTT to File System file sink configuration..."

### Input to unbacked
inputMqttTopic="data/input/valid"
replace_placeholders_in_template_and_apply "$mqttFileSystemTemplate" "$acsaUnbackedEndpointName-data-input" "$acsaUnbackedEndpointName" "$inputMqttTopic" "data-input"

### Devices health to unbacked
devicesHealthMqttTopic="metrics/aio/devices-health"
replace_placeholders_in_template_and_apply "$mqttFileSystemTemplate" "$acsaUnbackedEndpointName-devices-health" "$acsaUnbackedEndpointName" "$devicesHealthMqttTopic" "devices-health"

### Machine status to cloud backed
machineStatusMqttTopic="metrics/aio/machine-status"
replace_placeholders_in_template_and_apply "$mqttFileSystemTemplate" "$acsaCloudBackedEndpointName-$METRIC1_TOPIC_PATH_NAME" "$acsaCloudBackedEndpointName" "$machineStatusMqttTopic" "$METRIC1_TOPIC_PATH_NAME"

### Total counter to cloud backed
totalCounterMqttTopic="metrics/aio/total-counter"
replace_placeholders_in_template_and_apply "$mqttFileSystemTemplate" "$acsaCloudBackedEndpointName-$METRIC2_TOPIC_PATH_NAME" "$acsaCloudBackedEndpointName" "$totalCounterMqttTopic" "$METRIC2_TOPIC_PATH_NAME"

# MQTT to Event Grid bidirectional dataflow
## Endpoints creation
eventGridEndpointName="eventgrid-${EVENT_GRID_NAMESPACE_NAME}"

# Export variables for eventgrid endpoint
export EVENT_GRID_NAMESPACE=$EVENT_GRID_NAMESPACE_NAME
export LOCATION=$LOCATION
export ENDPOINT_NAME=$eventGridEndpointName

# Apply the template using envsubst
apply_template_with_envsubst "../yaml/endpoints/eventgrid-df-endpoint.yaml" | kubectl apply -f -

## Dataflows creation
mqttEventGridTemplate="mqtt-cloud/mqtt-to-event-grid-df"
eventGridMqttTemplate="mqtt-cloud/event-grid-to-mqtt-df"
echo "Applying the MQTT to Event Grid bidirectional connection configuration..."

## Machine status
replace_placeholders_in_template_and_apply "$mqttEventGridTemplate" "$METRIC1_TOPIC_PATH_NAME" "$eventGridEndpointName" "$machineStatusMqttTopic" "$METRIC1_TOPIC_PATH_NAME"

machineStatusEventGridMqttTopic="metrics/aio/machine-status/event-grid"
replace_placeholders_in_template_and_apply "$eventGridMqttTemplate" "$METRIC1_TOPIC_PATH_NAME" "$eventGridEndpointName" "$METRIC1_TOPIC_PATH_NAME" "$machineStatusEventGridMqttTopic"

## Total counter
replace_placeholders_in_template_and_apply "$mqttEventGridTemplate" "$METRIC2_TOPIC_PATH_NAME" "$eventGridEndpointName" "$totalCounterMqttTopic" "$METRIC2_TOPIC_PATH_NAME"

totalCounterEventGridMqttTopic="metrics/aio/total-counter/event-grid"
replace_placeholders_in_template_and_apply "$eventGridMqttTemplate" "$METRIC2_TOPIC_PATH_NAME" "$eventGridEndpointName" "$METRIC2_TOPIC_PATH_NAME" "$totalCounterEventGridMqttTopic"

## Devices health
devicesHealthMqttTopic="metrics/aio/devices-health"
replace_placeholders_in_template_and_apply "$mqttEventGridTemplate" "$METRIC3_TOPIC_TEMPLATE_NAME" "$eventGridEndpointName" "$devicesHealthMqttTopic" "$METRIC3_TOPIC_TEMPLATE_NAME"

devicesHealthEventGridMqttTopic="metrics/aio/devices-health/event-grid"
replace_placeholders_in_template_and_apply "$eventGridMqttTemplate" "$METRIC3_TOPIC_TEMPLATE_NAME" "$eventGridEndpointName" "$METRIC3_TOPIC_TEMPLATE_NAME" "$devicesHealthEventGridMqttTopic"
