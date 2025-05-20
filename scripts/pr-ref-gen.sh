#!/usr/bin/env bash

# Script to generate a PR reference file with commit history and full diff
# This file will be used by GitHub Copilot to generate accurate PR descriptions
#
# The script compares the current branch with a specified base branch (default: main)
# and generates an XML file with commit history and diff information

# Display usage information
function show_usage {
  echo "Usage: $0 [--no-md-diff] [--base-branch BRANCH]"
  echo ""
  echo "Options:"
  echo "  --no-md-diff       Exclude markdown files (*.md) from the diff output"
  echo "  --base-branch      Specify the base branch to compare against (default: main)"
  exit 1
}

# Process command line arguments
NO_MD_DIFF=false
BASE_BRANCH="main"
while [[ $# -gt 0 ]]; do
  case "$1" in
  --no-md-diff)
    NO_MD_DIFF=true
    shift
    ;;
  --base-branch)
    if [[ -z $2 || $2 == --* ]]; then
      echo "Error: --base-branch requires an argument"
      show_usage
    fi
    BASE_BRANCH="$2"
    shift 2
    ;;
  --help | -h)
    show_usage
    ;;
  *)
    echo "Unknown option: $1"
    show_usage
    ;;
  esac
done

# Verify the base branch exists
if ! git rev-parse --verify "${BASE_BRANCH}" &>/dev/null; then
  echo "Error: Branch '${BASE_BRANCH}' does not exist or is not accessible"
  exit 1
fi

# Get the repository root directory
REPO_ROOT=$(git rev-parse --show-toplevel)
PR_REF_FILE="${REPO_ROOT}/.copilot-tracking/pr/pr-reference.xml"
mkdir -p "$(dirname "$PR_REF_FILE")"

# Create the reference file with commit history using XML tags
{
  echo "<commit_history>"
  echo "  <current_branch>"
  git --no-pager branch --show-current
  echo "  </current_branch>"
  echo ""

  echo "  <base_branch>"
  echo "    ${BASE_BRANCH}"
  echo "  </base_branch>"
  echo ""

  echo "  <commits>"
  # Output commit information including subject and body
  git --no-pager log --pretty=format:"<commit hash=\"%h\" date=\"%cd\"><message><subject><\![CDATA[%s]]></subject><body><\![CDATA[%b]]></body></message></commit>" --date=short "${BASE_BRANCH}"..HEAD
  echo "  </commits>"
  echo ""

  # Add the full diff, excluding specified files
  echo "  <full_diff>"
  # Exclude prompts and this file from diff history
  if [ "$NO_MD_DIFF" = true ]; then
    git --no-pager diff "${BASE_BRANCH}" -- ':!*.md'
  else
    git --no-pager diff "${BASE_BRANCH}"
  fi
  echo "  </full_diff>"
  echo "</commit_history>"
} >"${PR_REF_FILE}"

LINE_COUNT=$(wc -l <"${PR_REF_FILE}" | awk '{print $1}')

echo "Created ${PR_REF_FILE}"
if [ "$NO_MD_DIFF" = true ]; then
  echo "Note: Markdown files were excluded from diff output"
fi
echo "Lines: $LINE_COUNT"
echo "Base branch: $BASE_BRANCH"
