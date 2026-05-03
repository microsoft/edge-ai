#!/usr/bin/env bash
# Build Python Atheris fuzz harnesses using the CFLite-canonical PyInstaller
# `--onefile` convention: one self-contained executable per harness, plus a
# small wrapper that sets ASAN options expected by the fuzzing engine.
set -euo pipefail

: "${OUT:?OUT must be set by ClusterFuzzLite}"
: "${SRC:?SRC must be set by ClusterFuzzLite}"

# Format: "<harness_name>:<service dir relative to repo root>:<harness path relative to service dir>"
HARNESSES=(
  "fuzz_models_505:src/500-application/505-akri-rest-http-connector/services/sensor-simulator:tests/fuzz/fuzz_models.py"
  "fuzz_message_registry_506:src/500-application/506-ros2-connector/services/ros2-connector:tests/fuzz/fuzz_message_registry.py"
  "fuzz_process_event_509:src/500-application/509-sse-connector/services/connector-test-client:tests/fuzz/fuzz_process_event.py"
  "fuzz_soap_parser_510:src/500-application/510-onvif-connector/services/onvif-camera-simulator:tests/fuzz/fuzz_soap_parser.py"
  "fuzz_smoke_505:src/500-application/505-akri-rest-http-connector/services/sensor-simulator:tests/fuzz/fuzz_smoke.py"
  "fuzz_smoke_509:src/500-application/509-sse-connector/services/connector-test-client:tests/fuzz/fuzz_smoke.py"
  "fuzz_smoke_510:src/500-application/510-onvif-connector/services/onvif-camera-simulator:tests/fuzz/fuzz_smoke.py"
)

if [[ ${#HARNESSES[@]} -eq 0 ]]; then
  echo "build_python.sh: no Python fuzz harnesses configured"
  exit 0
fi

# atheris and pyinstaller are pre-installed in the Dockerfile for the python
# language path so they are available before the OSS-Fuzz `compile` wrapper
# runs. Local-repro fallbacks below cover environments using a stock
# base-builder-python image.
if ! command -v pyinstaller >/dev/null 2>&1; then
  python3 -m pip install --no-cache-dir pyinstaller
fi

if ! python3 -c "import atheris" >/dev/null 2>&1; then
  python3 -m pip install --no-cache-dir atheris
fi

for entry in "${HARNESSES[@]}"; do
  IFS=':' read -r harness_name svc_dir harness_rel <<<"${entry}"
  svc_path="${SRC}/edge-ai/${svc_dir}"

  pushd "${svc_path}" >/dev/null
  if [[ -f requirements.txt ]]; then
    pip3 install --no-cache-dir -r requirements.txt
  fi
  pyinstaller \
    --distpath "${OUT}" \
    --onefile \
    --name "${harness_name}.pkg" \
    --paths "${svc_path}" \
    --collect-submodules src.message_types \
    "${svc_path}/${harness_rel}"
  popd >/dev/null

  cat >"${OUT}/${harness_name}" <<WRAPPER
#!/usr/bin/env bash
this_dir=\$(dirname "\$0")
export ASAN_OPTIONS="\${ASAN_OPTIONS:-}:detect_leaks=0:symbolize=1:external_symbolizer_path=\$this_dir/llvm-symbolizer"
exec "\$this_dir/${harness_name}.pkg" "\$@"
WRAPPER
  chmod +x "${OUT}/${harness_name}"
done
