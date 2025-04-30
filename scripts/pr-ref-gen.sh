#!/usr/bin/env bash

# Script to generate a PR reference file with commit history and full diff
# This file will be used by GitHub Copilot to generate accurate PR descriptions

# Display usage information
function show_usage {
  echo "Usage: $0 [--no-md-diff]"
  echo ""
  echo "Options:"
  echo "  --no-md-diff    Exclude markdown files (*.md) from the diff output"
  exit 1
}

# Process command line arguments
NO_MD_DIFF=false
while [[ $# -gt 0 ]]; do
  case "$1" in
  --no-md-diff)
    NO_MD_DIFF=true
    shift
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

# Get the repository root directory
REPO_ROOT=$(git rev-parse --show-toplevel)
PR_REF_FILE="${REPO_ROOT}/pr-reference.xml"

# Create the reference file with commit history using XML tags
{
  echo "<commit_history>"
  echo "  <current_branch>"
  git --no-pager branch --show-current
  echo "  </current_branch>"
  echo ""

  echo "  <commits>"
  # Output commit information including subject and body
  git --no-pager log --pretty=format:"<commit hash=\"%h\" date=\"%cd\"><message><subject><\![CDATA[%s]]></subject><body><\![CDATA[%b]]></body></message></commit>" --date=short main..HEAD
  echo "  </commits>"
  echo ""

  # Add the full diff, excluding specified files
  echo "  <full_diff>"
  # Exclude prompts and this file from diff history
  if [ "$NO_MD_DIFF" = true ]; then
    git --no-pager diff main -- ':!.github/copilot-instructions.md' ':!.github/prompts/*' ':!.vscode/settings.json' ':!scripts/pr-ref-gen.sh' ':!*.md'
  else
    git --no-pager diff main -- ':!.github/copilot-instructions.md' ':!.github/prompts/*' ':!.vscode/settings.json' ':!scripts/pr-ref-gen.sh'
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
