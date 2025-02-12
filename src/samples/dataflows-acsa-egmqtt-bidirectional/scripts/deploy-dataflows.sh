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

    # Escape special characters in variables so sed will know how to replace them
    local escapedDataSource
    escapedDataSource=$(echo "$dataSource" | sed 's/\//\\\//g')
    local escapedDataDestination
    escapedDataDestination=$(echo "$dataDestination" | sed 's/\//\\\//g')

    sed -e "s/{UNIQUE_POSTFIX}/$uniquePostfix/g" \
        -e "s/{ENDPOINT_NAME}/$endpointName/g" \
        -e "s/{DATA_SOURCE}/$escapedDataSource/g" \
        -e "s/{DATA_DESTINATION}/$escapedDataDestination/g" \
        ../yaml/"$templatePathName".yaml | kubectl apply -f -
}

verify_kubectl_installed
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

sed -e "s/{PVC_NAME}/$ACSA_UNBACKED_AIO_PVC_NAME/g" \
    -e "s/{ENDPOINT_NAME}/$acsaUnbackedEndpointName/g" \
    ../yaml/endpoints/acsa-df-endpoint.yaml | kubectl apply -f -

sed -e "s/{PVC_NAME}/$ACSA_CLOUD_BACKED_AIO_PVC_NAME/g" \
    -e "s/{ENDPOINT_NAME}/$acsaCloudBackedEndpointName/g" \
    ../yaml/endpoints/acsa-df-endpoint.yaml | kubectl apply -f -

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
replace_placeholders_in_template_and_apply "$mqttFileSystemTemplate"  "$acsaCloudBackedEndpointName-$METRIC1_TOPIC_PATH_NAME" "$acsaCloudBackedEndpointName" "$machineStatusMqttTopic" "$METRIC1_TOPIC_PATH_NAME"

### Total counter to cloud backed
totalCounterMqttTopic="metrics/aio/total-counter"
replace_placeholders_in_template_and_apply "$mqttFileSystemTemplate"  "$acsaCloudBackedEndpointName-$METRIC2_TOPIC_PATH_NAME" "$acsaCloudBackedEndpointName" "$totalCounterMqttTopic" "$METRIC2_TOPIC_PATH_NAME"

# MQTT to Event Grid bidirectional dataflow
## Endpoints creation
eventGridEndpointName="eventgrid-${EVENT_GRID_NAMESPACE_NAME}"
sed -e "s/{EVENT_GRID_NAMESPACE}/$EVENT_GRID_NAMESPACE_NAME/g" \
    -e "s/{LOCATION}/$LOCATION/g" \
    -e "s/{ENDPOINT_NAME}/$eventGridEndpointName/g" \
    ../yaml/endpoints/eventgrid-df-endpoint.yaml | kubectl apply -f -

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
