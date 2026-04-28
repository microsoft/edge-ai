#!/usr/bin/env bash
# Build Python Atheris fuzz harnesses. No harnesses scoped for this phase.
set -euo pipefail

: "${OUT:?OUT must be set by ClusterFuzzLite}"

# Format: "<harness_name>:<absolute path to harness .py>"
HARNESSES=(
  "fuzz_models_505:$SRC/edge-ai/src/500-application/505-akri-rest-http-connector/services/sensor-simulator/tests/fuzz/fuzz_models.py"
  "fuzz_message_registry_506:$SRC/edge-ai/src/500-application/506-ros2-connector/services/ros2-connector/tests/fuzz/fuzz_message_registry.py"
  "fuzz_process_event_509:$SRC/edge-ai/src/500-application/509-sse-connector/services/connector-test-client/tests/fuzz/fuzz_process_event.py"
  "fuzz_soap_parser_510:$SRC/edge-ai/src/500-application/510-onvif-connector/services/onvif-camera-simulator/tests/fuzz/fuzz_soap_parser.py"
)

if [[ ${#HARNESSES[@]} -eq 0 ]]; then
  echo "build_python.sh: no Python fuzz harnesses configured"
  exit 0
fi

for entry in "${HARNESSES[@]}"; do
  harness_name="${entry%%:*}"
  harness_path="${entry#*:}"
  out_path="${OUT}/${harness_name}"

  cat >"${out_path}" <<'WRAPPER'
#!/usr/bin/env bash
this_dir=$(dirname "$0")
ASAN_OPTIONS="$ASAN_OPTIONS:symbolize=1:external_symbolizer_path=$this_dir/llvm-symbolizer:detect_leaks=0" \
    python3.12 "$this_dir/HARNESS_FILE" "$@"
WRAPPER
  sed -i "s|HARNESS_FILE|$(basename "${harness_path}")|" "${out_path}"
  chmod +x "${out_path}"
  cp "${harness_path}" "${OUT}/$(basename "${harness_path}")"
done
