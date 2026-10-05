#!/usr/bin/env bash
# Install a pinned, checksum-verified static ffmpeg build for the Azure Functions Linux host.
# Runs during function app deployment. The archive is verified with SHA-256 before extraction.

set -euo pipefail

FFMPEG_VERSION="${FFMPEG_VERSION:-7.0.2}"
FFMPEG_SHA256="${FFMPEG_SHA256:-abda8d77ce8309141f83ab8edf0596834087c52467f6badf376a6a2a4c87cf67}"
FFMPEG_ARCHIVE="ffmpeg-${FFMPEG_VERSION}-amd64-static.tar.xz"

# The provider moves superseded builds from releases/ to old-releases/; try both.
FFMPEG_URLS=(
  "https://johnvansickle.com/ffmpeg/releases/${FFMPEG_ARCHIVE}"
  "https://johnvansickle.com/ffmpeg/old-releases/${FFMPEG_ARCHIVE}"
)

if [[ -z "${HOME:-}" || ! -d "${HOME}" ]]; then
  echo "Not in Azure Functions environment, skipping installation"
  exit 0
fi

INSTALL_DIR="${HOME}/bin"
mkdir -p "${INSTALL_DIR}"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT

downloaded=""
for url in "${FFMPEG_URLS[@]}"; do
  echo "Downloading ffmpeg ${FFMPEG_VERSION} from ${url}..."
  if curl -fsSL --proto '=https' --tlsv1.2 "${url}" -o "${TEMP_DIR}/${FFMPEG_ARCHIVE}"; then
    downloaded="true"
    break
  fi
done

if [[ -z "${downloaded}" ]]; then
  echo "✗ Failed to download ${FFMPEG_ARCHIVE}" >&2
  exit 1
fi

echo "Verifying SHA-256..."
if ! echo "${FFMPEG_SHA256}  ${TEMP_DIR}/${FFMPEG_ARCHIVE}" | sha256sum --check --strict --status; then
  echo "✗ SHA-256 verification failed for ${FFMPEG_ARCHIVE}" >&2
  exit 1
fi

echo "Extracting ffmpeg..."
tar -xJf "${TEMP_DIR}/${FFMPEG_ARCHIVE}" -C "${TEMP_DIR}"

FFMPEG_BIN="${TEMP_DIR}/ffmpeg-${FFMPEG_VERSION}-amd64-static/ffmpeg"
if [[ ! -f "${FFMPEG_BIN}" ]]; then
  echo "✗ ffmpeg binary not found in ${FFMPEG_ARCHIVE}" >&2
  exit 1
fi

install -m 0755 "${FFMPEG_BIN}" "${INSTALL_DIR}/ffmpeg"
echo "✓ ffmpeg installed to ${INSTALL_DIR}/ffmpeg"

export PATH="${INSTALL_DIR}:${PATH}"
if command -v ffmpeg &>/dev/null; then
  ffmpeg -version | sed -n 1p
  echo "✓ ffmpeg is ready"
else
  echo "✗ ffmpeg not found in PATH" >&2
  exit 1
fi
