#! /bin/bash

set -e

# shellcheck disable=SC1091
source ./utils/common.sh

verify_azcli_installed
verify_kubectl_installed

test_kubeapi_connection_with_retry

echo "== Enabling ACSA Persistent Volume Claims =="

echo "Getting required environment variables"
ACSA_UNBACKED_AIO_PVC_NAME=${ACSA_UNBACKED_AIO_PVC_NAME:-"pvc-acsa-unbacked-aio"}
ACSA_CLOUD_BACKED_AIO_PVC_NAME=${ACSA_CLOUD_BACKED_AIO_PVC_NAME:-"pvc-acsa-cloud-backed-aio"}

navigate_to_scripts_dir

# Create an unbacked PVC to be used by the ACSA for storing Json Time Series data
echo "Creating unbacked PVC $ACSA_UNBACKED_AIO_PVC_NAME in the namespace azure-iot-operations"
sed -e "s/{ACSA_UNBACKED_PVC_NAME}/$ACSA_UNBACKED_AIO_PVC_NAME/g" \
    -e "s/{NAMESPACE}/azure-iot-operations/g" \
    ../yaml/acsa/unbackedPVC.yaml | kubectl apply -f -

# Create an unbacked PVC viewer to be able to see Json Time Series data in the unbacked PVC
echo "Creating unbacked PVC $ACSA_UNBACKED_AIO_PVC_NAME viewer pod in the namespace azure-iot-operations"
sed -e "s/{ACSA_UNBACKED_PVC_NAME}/$ACSA_UNBACKED_AIO_PVC_NAME/g" \
    -e "s/{NAMESPACE}/azure-iot-operations/g" \
    ../yaml/acsa/acsa-local.yaml | kubectl apply -f -

# Create a cloud backed PVC to be used by the ACSA for the storing Json Time Series data
echo "Creating cloud backed PVC $ACSA_CLOUD_BACKED_AIO_PVC_NAME in the namespace azure-iot-operations"
sed -e "s/{ACSA_CLOUD_BACKED_PVC_NAME}/$ACSA_CLOUD_BACKED_AIO_PVC_NAME/g" \
    -e "s/{NAMESPACE}/azure-iot-operations/g" \
    ../yaml/acsa/cloudBackedPVC.yaml | kubectl apply -f -
