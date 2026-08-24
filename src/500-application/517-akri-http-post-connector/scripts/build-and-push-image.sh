#!/usr/bin/env bash
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

set -euo pipefail

# Builds and pushes the Akri HTTP POST Connector runtime image to an ACR.
# Usage: ./build-and-push-image.sh <acr_name> [image_tag] [--build-root-ca <path>]

usage() {
	echo "Usage: ${0##*/} <acr_name> [image_tag] [--build-root-ca <path>]"
}

main() {
	command -v jq >/dev/null 2>&1 || {
		echo "jq CLI required" >&2
		exit 1
	}

	if [[ $# -eq 0 ]]; then
		usage >&2
		exit 1
	fi

	local acr_name="$1"
	shift

	local image_tag=""
	if [[ $# -gt 0 && "$1" != --* ]]; then
		image_tag="$1"
		shift
	fi

	local build_root_ca=""
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--build-root-ca)
				if [[ -z "${2:-}" || "$2" == --* ]]; then
					echo "--build-root-ca requires a certificate file path" >&2
					exit 1
				fi
				build_root_ca="$2"
				shift 2
				;;
			--help|-h)
				usage
				exit 0
				;;
			*)
				echo "Unknown option: $1" >&2
				usage >&2
				exit 1
				;;
		esac
	done

	if [[ -n "${build_root_ca}" && \
		( ! -f "${build_root_ca}" || ! -r "${build_root_ca}" ) ]]; then
		echo "Build root CA is not a readable file: ${build_root_ca}" >&2
		exit 1
	fi

	local script_dir
	local app_dir
	local service_dir
	local metadata_file
	local crate_version
	local metadata_image_tag
	local image_ref
	script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	app_dir="$(cd "${script_dir}/.." && pwd)"
	service_dir="${app_dir}/services/akri-http-post-connector"
	metadata_file="${app_dir}/connector-metadata/connector-metadata.json"
	crate_version="$(grep '^version' "${service_dir}/Cargo.toml" | head -1 | sed 's/.*= *"\(.*\)"/\1/')"
	metadata_image_tag="$(jq -r '.imageConfigurationSettings.tag' "${metadata_file}")"
	image_tag="${image_tag:-${crate_version}}"
	image_ref="${acr_name}.azurecr.io/akri-http-post-connector:${image_tag}"

	if [[ "${image_tag}" != "${crate_version}" || \
		"${metadata_image_tag}" != "${crate_version}" ]]; then
		echo "Image tag, metadata image tag, and Cargo package version must all match" >&2
		exit 1
	fi

	local -a build_command=(
		docker build
		-f "${service_dir}/Dockerfile"
		-t "${image_ref}"
	)
	if [[ -n "${build_root_ca}" ]]; then
		build_command+=(
			--secret "id=build_root_ca,src=${build_root_ca}"
		)
	fi
	build_command+=("${service_dir}")

	echo "Building ${image_ref} from ${service_dir}"
	"${build_command[@]}"

	echo "Logging in to ACR: ${acr_name}"
	az acr login --name "${acr_name}"

	echo "Pushing ${image_ref}"
	docker push "${image_ref}"

	echo "Pushed ${image_ref}"
}

main "$@"
