#!/bin/bash

# Usage: init.sh
# Description: Downloads GitHub workflow templates from Kalypso repository and creates a PR

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
KALYPSO_REPO="https://github.com/microsoft/kalypso"
TEMP_DIR="${SCRIPT_DIR}/tmp"

print_usage() {
  printf "Usage: %s\n" "${0##*/}"
  printf "\nDescription: Downloads GitHub workflow templates from Kalypso repository and creates a PR\n"
  printf "\nThis script will:\n"
  printf "  - Clone the Kalypso repository\n"
  printf "  - Copy .github/workflows/templates to .github/workflows/templates\n"
  printf "  - Copy cicd/setup.sh to src/501-ci-cd/setup.sh\n"
  printf "  - Create a new branch and commit changes\n"
  printf "  - Create a pull request\n"
  printf "\nPrerequisites:\n"
  printf "  - gh CLI must be installed and authenticated\n"
  printf "  - git must be configured with user name and email\n"
}

check_prerequisites() {
  local missing_tools=()

  if ! command -v gh >/dev/null 2>&1; then
    missing_tools+=("gh")
  fi

  if ! command -v git >/dev/null 2>&1; then
    missing_tools+=("git")
  fi

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    printf "Error: Missing required tools: %s\n" "${missing_tools[*]}"
    printf "Please install the missing tools and try again.\n"
    return 1
  fi

  # Check git configuration
  if ! git config --get user.name >/dev/null || ! git config --get user.email >/dev/null; then
    printf "Error: Git user name and email are not configured\n"
    printf "Please run:\n"
    printf "  git config --global user.name \"Your Name\"\n"
    printf "  git config --global user.email \"your.email@example.com\"\n"
    return 1
  fi

  # Check gh authentication
  if ! gh auth status >/dev/null 2>&1; then
    printf "Error: GitHub CLI is not authenticated\n"
    printf "Please run: gh auth login\n"
    return 1
  fi
}

cleanup() {
  if [[ -d "${TEMP_DIR}" ]]; then
    rm -rf "${TEMP_DIR}"
  fi
}

download_kalypso_files() {
  printf "Downloading files from Kalypso repository...\n"

  # Create temp directory
  mkdir -p "${TEMP_DIR}"

  # Clone Kalypso repository
  git clone "${KALYPSO_REPO}" "${TEMP_DIR}/kalypso"

  # Verify required directories exist
  if [[ ! -d "${TEMP_DIR}/kalypso/.github/workflows/templates" ]]; then
    printf "Error: .github/workflows/templates directory not found in Kalypso repository\n"
    return 1
  fi

  if [[ ! -f "${TEMP_DIR}/kalypso/cicd/setup.sh" ]]; then
    printf "Error: cicd/setup.sh file not found in Kalypso repository\n"
    return 1
  fi
}

copy_workflow_templates() {
  printf "Copying GitHub workflow templates...\n"

  local target_dir="${REPO_ROOT}/.github/workflows/templates"

  # Create target directory if it doesn't exist
  mkdir -p "${target_dir}"

  # Copy all files from templates directory
  cp -r "${TEMP_DIR}/kalypso/.github/workflows/templates/"* "${target_dir}/"

  printf "Copied workflow templates to %s\n" "${target_dir}"
}

copy_setup_script() {
  printf "Copying setup script...\n"

  local target_file="${SCRIPT_DIR}/setup.sh"

  # Copy setup.sh to ci-cd directory
  cp "${TEMP_DIR}/kalypso/cicd/setup.sh" "${target_file}"

  # Make it executable
  chmod +x "${target_file}"

  printf "Copied setup script to %s\n" "${target_file}"
}

create_pr() {
  printf "Creating pull request...\n"

  cd "${REPO_ROOT}"

  # Check if we're in a git repository
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    printf "Error: Not in a git repository\n"
    return 1
  fi

  # Create a new branch
  local branch_name
  branch_name="feature/kalypso-cicd-templates-$(date +%Y%m%d-%H%M%S)"
  git checkout -b "${branch_name}"

  # Add changes
  git add .github/workflows/templates src/501-ci-cd/setup.sh

  # Check if there are changes to commit
  if git diff --cached --quiet; then
    printf "No changes to commit\n"
    git checkout -
    git branch -d "${branch_name}"
    return 0
  fi

  # Commit changes
  git commit -m "feat: add Kalypso CI/CD workflow templates and setup script

- Add GitHub workflow templates from microsoft/kalypso repository
- Add setup script for GitOps CI/CD configuration
- Templates include CI, CD, post-deployment, and notification workflows
- Setup script enables GitOps repository configuration and PR automation"

  # Push branch
  git push origin "${branch_name}"

  # Create pull request - check if this is a GitHub repository
  if gh pr create \
    --title "Add Kalypso CI/CD workflow templates and setup script" \
    --body "This PR adds GitHub workflow templates and setup script from the microsoft/kalypso repository to enable GitOps CI/CD workflows.

## Changes
- **GitHub Workflow Templates**: Added CI/CD workflow templates from Kalypso
  - \`ci.yml\`: Continuous integration workflow
  - \`cd.yml\`: Continuous deployment workflow
  - \`post-deployment.yml\`: Post-deployment validation workflow
  - \`notify-on-pr.yml\`: GitOps PR notification workflow
  - \`notify-on-config-change.yml\`: Configuration change notification workflow
  - Supporting utility scripts in \`utils/\` directory

- **Setup Script**: Added \`src/501-ci-cd/setup.sh\` for GitOps repository configuration
  - Automates creation of GitOps and configuration repositories
  - Configures GitHub secrets and variables
  - Sets up promotional flow between environments
  - Creates necessary branches and workflows

## Source
Files copied from: https://github.com/microsoft/kalypso
- \`.github/workflows/templates/\` → \`.github/workflows/templates/\`
- \`cicd/setup.sh\` → \`src/501-ci-cd/setup.sh\`

## Usage
The setup script can be used to bootstrap GitOps CI/CD for applications:
\`\`\`bash
cd src/501-ci-cd
./setup.sh -o <github-org> -r <repo-name> -e <environment>
\`\`\`

The workflow templates provide a complete GitOps promotional flow implementation." \
    --assignee "@me" 2>/dev/null; then
    printf "Pull request created successfully!\n"
  else
    printf "Note: Could not create GitHub PR automatically (repository may not be on GitHub)\n"
    printf "Please create a pull request manually in your repository's web interface.\n"
    printf "\nBranch created: %s\n" "${branch_name}"
    printf "Files added:\n"
    printf "  - .github/workflows/templates/ (CI/CD workflow templates)\n"
    printf "  - src/501-ci-cd/setup.sh (GitOps setup script)\n"
  fi
}

main() {
  # Set trap for cleanup
  trap cleanup EXIT

  printf "Kalypso CI/CD Templates Import Script\n"
  printf "=====================================\n\n"

  if ! check_prerequisites; then
    return 1
  fi

  if ! download_kalypso_files; then
    return 1
  fi

  copy_workflow_templates
  copy_setup_script

  if ! create_pr; then
    return 1
  fi

  printf "\nScript completed successfully!\n"
}

# Handle script arguments
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
  print_usage
  exit 0
fi

main "$@"
