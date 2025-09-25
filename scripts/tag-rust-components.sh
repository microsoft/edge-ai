#!/usr/bin/env bash
set -euo pipefail

# Tag Rust components based on the version in their Cargo.toml files.
# Tags are created in the form: <component-name>/<semver>
#
# Usage: $0 [-n] [-f] [-p] [components_dir]
#
# Options:
#   -n  Dry run (print actions without creating tags)
#   -f  Force (replace existing local tag and push with --force when -p is used)
#   -p  Push created tags to origin
#
# Arguments:
#   components_dir  Directory containing Rust components (default: current directory)

dry_run=false
force=false
push=false

while getopts ":nfp" opt; do
  case ${opt} in
    n) dry_run=true ;;
    f) force=true ;;
    p) push=true ;;
    *) echo "Usage: $0 [-n] [-f] [-p] [components_dir]" >&2; exit 2 ;;
  esac
done

shift $((OPTIND-1))

# Set components directory from parameter or use current directory as default
components_dir="${1:-.}"
components_dir=$(cd "${components_dir}" && pwd)

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root="$script_dir/.."

if ! git -C "$repo_root" rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error: not a git repository: $repo_root" >&2
  exit 1
fi

if [ ! -d "$components_dir" ]; then
  echo "Error: components directory not found: $components_dir" >&2
  exit 1
fi

extract_version() {
  # Extract the package.version from the [package] section only
  # Usage: extract_version <path-to-Cargo.toml>
  awk '
    BEGIN { inpkg=0 }
    /^\[package\]/ { inpkg=1; next }
    inpkg && /^\[/ { inpkg=0 }
    inpkg && /^[[:space:]]*version[[:space:]]*=/ {
      if (match($0, /"[^"]+"/)) {
        v=substr($0, RSTART+1, RLENGTH-2);
        print v;
        exit 0;
      }
    }
  ' "$1"
}

created=0
skipped=0
updated=0

for comp_path in "$components_dir"/*; do
  [ -d "$comp_path" ] || continue
  cargo_toml="$comp_path/Cargo.toml"
  if [ ! -f "$cargo_toml" ]; then
    # Not a Rust component; skip
    continue
  fi

  comp_name=$(basename "$comp_path")
  version=$(extract_version "$cargo_toml" || true)
  if [ -z "${version:-}" ]; then
    echo "WARN: No version found in $comp_name/Cargo.toml (skipping)" >&2
    ((skipped++))
    continue
  fi

  tag="$comp_name/$version"
  if git -C "$repo_root" show-ref --tags --quiet --verify "refs/tags/$tag"; then
    if [ "$force" = true ]; then
      echo "Updating existing tag: $tag"
      if [ "$dry_run" = true ]; then
        echo "DRY-RUN: git tag -a -f '$tag' -m 'Tag $comp_name $version'"
      else
        git -C "$repo_root" tag -a -f "$tag" -m "Tag $comp_name $version"
      fi
      if [ "$push" = true ]; then
        if [ "$dry_run" = true ]; then
          echo "DRY-RUN: git push -f origin '$tag'"
        else
          git -C "$repo_root" push -f origin "$tag"
        fi
      fi
      ((updated++))
    else
      echo "Tag exists, skipping: $tag"
      ((skipped++))
    fi
    continue
  fi

  echo "Creating tag: $tag"
  if [ "$dry_run" = true ]; then
    echo "DRY-RUN: git tag -a '$tag' -m 'Tag $comp_name $version'"
  else
    if [ "$force" = true ]; then
      git -C "$repo_root" tag -a -f "$tag" -m "Tag $comp_name $version"
    else
      git -C "$repo_root" tag -a "$tag" -m "Tag $comp_name $version"
    fi
  fi

  if [ "$push" = true ]; then
    if [ "$dry_run" = true ]; then
      echo "DRY-RUN: git push origin '$tag'"
    else
      if [ "$force" = true ]; then
        git -C "$repo_root" push -f origin "$tag"
      else
        git -C "$repo_root" push origin "$tag"
      fi
    fi
  fi
  ((created++))
done

echo "Summary: created=$created, updated=$updated, skipped=$skipped"
