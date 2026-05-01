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

  cat >"${out_path}" <<'WRAPPER'
#!/usr/bin/env bash
this_dir=$(dirname "$0")
npx jazzer "$this_dir/HARNESS_FILE" "$@"
WRAPPER
  sed -i "s|HARNESS_FILE|$(basename "${harness_path}")|" "${out_path}"
  chmod +x "${out_path}"
  cp "${harness_path}" "${OUT}/$(basename "${harness_path}")"
done
