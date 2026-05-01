#!/usr/bin/env bash
# Build JavaScript Jazzer.js fuzz harnesses. The base-builder-javascript image
# preinstalls @jazzer.js/core globally; we additionally install the harness
# service's npm dependencies so any local imports resolve at runtime.
set -euo pipefail

: "${OUT:?OUT must be set by ClusterFuzzLite}"
: "${SRC:?SRC must be set by ClusterFuzzLite}"

# Format: "<harness_name>:<absolute path to harness .mjs>"
HARNESSES=(
  "fuzz_processAlerts_513:$SRC/edge-ai/src/500-application/513-tiered-notification-service/tests/fuzz/fuzz_processAlerts.mjs"
  "fuzz_smoke_513:$SRC/edge-ai/src/500-application/513-tiered-notification-service/tests/fuzz/fuzz_smoke.mjs"
)

if [[ ${#HARNESSES[@]} -eq 0 ]]; then
  echo "build_js.sh: no JavaScript fuzz harnesses configured"
  exit 0
fi

# Install npm dependencies for harness service(s) so local module resolution
# works inside the wrapper at fuzz time.
pushd "${SRC}/edge-ai/src/500-application/513-tiered-notification-service" >/dev/null
if [[ -f package-lock.json ]]; then
  npm ci
else
  npm install
fi
popd >/dev/null

for entry in "${HARNESSES[@]}"; do
  harness_name="${entry%%:*}"
  harness_path="${entry#*:}"
  out_path="${OUT}/${harness_name}"
  svc_dir="$(dirname "$(dirname "$(dirname "${harness_path}")")")"

  # Run the harness in place so its relative imports (e.g. ../../src/...)
  # resolve against the original service tree instead of a flattened OUT dir.
  cat >"${out_path}" <<WRAPPER
#!/usr/bin/env bash
cd "${svc_dir}"
exec npx jazzer "${harness_path}" "\$@"
WRAPPER
  chmod +x "${out_path}"
done
