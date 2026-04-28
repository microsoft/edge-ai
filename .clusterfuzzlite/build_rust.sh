#!/usr/bin/env bash
# Build all Rust cargo-fuzz harnesses discovered under src/ and copy artifacts to $OUT.
set -euo pipefail

: "${SRC:?SRC must be set by ClusterFuzzLite}"
: "${OUT:?OUT must be set by ClusterFuzzLite}"

REPO_ROOT="${SRC}/edge-ai"
RUST_TOOLCHAIN="nightly-2026-04-01"

shopt -s nullglob globstar

mapfile -t fuzz_dirs < <(find "${REPO_ROOT}/src" -type d -name fuzz -not -path '*/target/*' | sort)

if [[ ${#fuzz_dirs[@]} -eq 0 ]]; then
  echo "build_rust.sh: no Rust fuzz harnesses discovered"
  exit 0
fi

for fuzz_dir in "${fuzz_dirs[@]}"; do
  crate_dir="$(dirname "${fuzz_dir}")"
  crate_name="$(basename "${crate_dir}")"
  echo "build_rust.sh: building harnesses in ${fuzz_dir}"

  pushd "${crate_dir}" >/dev/null
  cargo "+${RUST_TOOLCHAIN}" fuzz build -O
  popd >/dev/null

  target_dir="${crate_dir}/fuzz/target/x86_64-unknown-linux-gnu/release"
  if [[ ! -d "${target_dir}" ]]; then
    echo "build_rust.sh: expected build output ${target_dir} not found" >&2
    exit 1
  fi

  for binary in "${target_dir}"/*; do
    [[ -f "${binary}" && -x "${binary}" ]] || continue
    harness_name="$(basename "${binary}")"
    cp "${binary}" "${OUT}/${crate_name}_${harness_name}"

    corpus_dir="${fuzz_dir}/corpus/${harness_name}"
    if [[ -d "${corpus_dir}" ]]; then
      (cd "${corpus_dir}" && zip -qr "${OUT}/${crate_name}_${harness_name}_seed_corpus.zip" .)
    fi
  done
done
