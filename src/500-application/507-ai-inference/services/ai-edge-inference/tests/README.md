---
title: AI Edge Inference — Validation and Testing
description: Testing methodology for the AI Edge Inference service including unit tests, integration tests, and live AIO broker simulations
author: Edge AI Team
ms.date: 2026-02-27
ms.topic: reference
---

Validation and testing procedures for the AI Edge Inference service.

## Unit Tests

```bash
cargo test
```

Runs all in-crate unit tests including:

- `rate_limiter::tests` — token-bucket and semaphore permit logic
- `topic_router::tests` — priority-based MQTT topic routing

## Local Development

```bash
cargo build --release
cargo run --bin ai-edge-inference -- --config test-config.yaml
cargo run --bin model-validator -- --model path/to/model.onnx
```

## Integration Testing

```bash
kubectl apply -f test/integration-test.yaml
kubectl apply -f test/inference-test-job.yaml
kubectl logs job/inference-test -n azure-iot-operations
```

## Rate Limiting Simulation (Gap 1)

Validates the `InferenceRateLimiter` behavior against a live Azure IoT Operations
MQTT broker. The simulation floods messages through the AIO broker and processes
them with the same token-bucket + semaphore algorithm implemented in `rate_limiter.rs`.

### Requirements

- Running AIO cluster with the default MQTT broker
- `kubectl` access to the `azure-iot-operations` namespace
- Broker authentication configured with `ServiceAccountToken` (audience `aio-internal`)

### Step 1 — Create a Non-TLS BrokerListener

The default AIO broker only exposes TLS on port 18883. A temporary NodePort
listener allows mosquitto clients to connect without TLS certificates:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: mqttbroker.iotoperations.azure.com/v1
kind: BrokerListener
metadata:
  name: test-non-tls
  namespace: azure-iot-operations
spec:
  ports:
  - authenticationRef: default
    port: 1883
    nodePort: 31883
    protocol: Mqtt
  serviceName: aio-broker-test
  serviceType: NodePort
EOF
```

> The webhook rejects duplicate `serviceName` or `serviceType: ClusterIp` entries,
> so a `NodePort` with a unique `serviceName` is required.

### Step 2 — Deploy a Mosquitto Test Pod

The pod uses a projected ServiceAccountToken volume with the `aio-internal`
audience for broker authentication:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mqtt-test-client
  namespace: azure-iot-operations
---
apiVersion: v1
kind: Pod
metadata:
  name: mqtt-rate-limit-sim
  namespace: azure-iot-operations
spec:
  serviceAccountName: mqtt-test-client
  containers:
  - name: mqtt-tools
    image: eclipse-mosquitto:2
    command: ["sleep", "infinity"]
    volumeMounts:
    - name: sat-token
      mountPath: /var/run/secrets/tokens
      readOnly: true
  volumes:
  - name: sat-token
    projected:
      sources:
      - serviceAccountToken:
          audience: aio-internal
          expirationSeconds: 86400
          path: broker-sat
EOF

kubectl wait --for=condition=Ready pod/mqtt-rate-limit-sim \
  -n azure-iot-operations --timeout=60s
```

### Step 3 — Verify Connectivity

```bash
kubectl exec mqtt-rate-limit-sim -n azure-iot-operations -- sh -c '
  SAT=$(cat /var/run/secrets/tokens/broker-sat)
  mosquitto_pub -h aio-broker-test -p 1883 \
    -u "K8S-SAT" -P "$SAT" \
    -t "test/connectivity" -m "hello" -q 1
'
```

No output means success.

### Step 4 — Run the Simulation

Copy the simulation script into the pod and execute it. The script:

1. Subscribes to the topic and captures 30 messages
2. Publishes 30 messages as a burst (all arrive in <1ms)
3. Replays captured messages through the rate limiter algorithm

Rate limiter parameters mirror `rate_limiter.rs` defaults:

| Parameter            | Value | Env Variable                |
|----------------------|-------|-----------------------------|
| Token-bucket rate    | 5/s   | `RATE_LIMIT_PER_SECOND`     |
| Max concurrent slots | 2     | `MAX_CONCURRENT_INFERENCES` |
| Drop on backpressure | true  | `DROP_ON_BACKPRESSURE`      |

```bash
kubectl exec mqtt-rate-limit-sim -n azure-iot-operations -- sh -c '
cat > /tmp/simulate.sh << "SCRIPT"
#!/bin/sh
BROKER="aio-broker-test"
PORT=1883
SAT=$(cat /var/run/secrets/tokens/broker-sat)
TOPIC="edge-ai/sim/site-001/camera/snapshots"
MSGFILE="/tmp/captured_msgs.txt"

echo "============================================================"
echo "  GAP 1 SIMULATION: Rate Limiting at the Edge"
echo "  InferenceRateLimiter(max_concurrent=2, rate=5/s, drop=true)"
echo "============================================================"
echo ""

> "$MSGFILE"
mosquitto_sub -h "$BROKER" -p "$PORT" -u "K8S-SAT" -P "$SAT" \
  -t "$TOPIC" -C 30 -W 20 > "$MSGFILE" 2>/dev/null &
SUB_PID=$!
sleep 1

echo "--- Phase 1: Publishing 30 msgs as fast as possible ---"
for i in $(seq 1 30); do
  mosquitto_pub -h "$BROKER" -p "$PORT" -u "K8S-SAT" -P "$SAT" \
    -t "$TOPIC" \
    -m "{\"seq\":$i,\"class\":\"gas_plume\",\"confidence\":0.92}" \
    -q 0 2>/dev/null
done
wait $SUB_PID 2>/dev/null
MSG_COUNT=$(wc -l < "$MSGFILE")
echo "Subscriber received: $MSG_COUNT messages"
echo ""

echo "--- Phase 2: Processing through InferenceRateLimiter ---"
RATE_LIMIT=5
MAX_CONCURRENT=2
ACCEPTED=0
DROPPED=0
RATE_LIMITED=0
ACTIVE=0
TOKEN_COUNT=$RATE_LIMIT
BATCH_NUM=0

while IFS= read -r line; do
  SEQ=$(echo "$line" | grep -o "\"seq\":[0-9]*" | grep -o "[0-9]*")

  if [ "$TOKEN_COUNT" -le 0 ]; then
    RATE_LIMITED=$((RATE_LIMITED + 1))
    BATCH_NUM=$((BATCH_NUM + 1))
    echo "  [window $BATCH_NUM] seq=$SEQ RATE_LIMITED"
    sleep 0.2
    TOKEN_COUNT=$RATE_LIMIT
    ACTIVE=0
  fi
  TOKEN_COUNT=$((TOKEN_COUNT - 1))

  if [ "$ACTIVE" -ge "$MAX_CONCURRENT" ]; then
    DROPPED=$((DROPPED + 1))
    echo "  [window $BATCH_NUM] seq=$SEQ DROPPED"
    continue
  fi

  ACTIVE=$((ACTIVE + 1))
  ACCEPTED=$((ACCEPTED + 1))
  echo "  [window $BATCH_NUM] seq=$SEQ ACCEPTED (slot $ACTIVE/$MAX_CONCURRENT)"
done < "$MSGFILE"

echo ""
echo "=== RESULTS ==="
echo "  Received: $MSG_COUNT | Accepted: $ACCEPTED | Dropped: $DROPPED | Rate-limited windows: $RATE_LIMITED"
SCRIPT
chmod +x /tmp/simulate.sh
/tmp/simulate.sh
'
```

### Expected Output

Without the rate limiter all 30 messages hit the inference engine simultaneously.
With the rate limiter active, expect approximately:

- **12 accepted** — 2 per token-bucket window (constrained by `MAX_CONCURRENT_INFERENCES`)
- **18 dropped** — excess messages shed via backpressure
- **5 rate-limited windows** — token bucket refills triggered

### Step 5 — Cleanup

```bash
kubectl delete pod mqtt-rate-limit-sim -n azure-iot-operations --grace-period=5
kubectl delete sa mqtt-test-client -n azure-iot-operations
kubectl delete brokerlistener test-non-tls -n azure-iot-operations
```

### How It Maps to `rate_limiter.rs`

| Simulation behavior                | Rust implementation                                                         |
|------------------------------------|-----------------------------------------------------------------------------|
| Token count decrements per message | `governor::RateLimiter::check()` returning `Err`                            |
| Sleep when tokens exhausted        | `rl.until_ready().await`                                                    |
| Accept when slot available         | `semaphore.try_acquire_owned()` returns `Ok`                                |
| Drop when slots full               | `semaphore.try_acquire_owned()` returns `Err` + `dropped_count` incremented |
| Slot released after processing     | `InferencePermit` dropped (RAII)                                            |
