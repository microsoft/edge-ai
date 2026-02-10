#!/usr/bin/env bash
set -euo pipefail

found=0
while IFS= read -r -d '' file; do
  found=1
  docker run --rm \
    -v "${PWD}:/workdir" \
    --workdir /workdir \
    hadolint/hadolint:v2.12.0-alpine \
    hadolint "$file"
done < <(find . -type f -name 'Dockerfile*' \
  -not -path './node_modules/*' \
  -not -path './.git/*' \
  -print0)

if [[ ${found} -eq 0 ]]; then
  printf '%s\n' 'No Dockerfiles found.'
fi
