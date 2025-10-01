# Testing the Basic Inference Pipeline

This directory contains a simple end-to-end test for the Basic Inference Pipeline application.

## Test Overview

The e2e test validates that the complete inference pipeline is working by:

1. Waiting for the MQTT broker to be available
2. Publishing a test message to the input topic
3. Verifying that an inference result is received on the output topic

## Running the Test

First, verify that the basic inference application and MQTT broker are running:

```bash
export NAMESPACE=<your-namespace>

# Check that all pods are running
kubectl get pods -n $NAMESPACE
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=basic-inference --timeout=300s -n $NAMESPACE
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=mosquitto --timeout=300s -n $NAMESPACE
```

Deploy the e2e test job to your Kubernetes cluster:

```bash
kubectl apply -f e2e-test-job.yaml -n $NAMESPACE
```

Check the test results:

```bash
# Wait for completion
kubectl wait --for=condition=complete job/e2e-test --timeout=300s -n $NAMESPACE

# View test logs
kubectl logs job/e2e-test -n $NAMESPACE

# Clean up
kubectl delete job e2e-test -n $NAMESPACE
```

## Test Details

- **Test Duration**: ~30 seconds
- **Test Message**: Single JSON message with test data
- **Success Criteria**: Receives at least one inference result within 20 seconds
- **Topics**:
  - Input: `device/sensor/telemetry`
  - Output: `inference/results`

## Prerequisites

- Basic inference application deployed and running in your target namespace
- MQTT broker accessible at `basic-inference-mosquitto:1883` within the same namespace
- Replace `<your-namespace>` in the commands above with your actual namespace (e.g., `dev-basic-inference-pipeline`, `qa-basic-inference-pipeline`)
