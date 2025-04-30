#!/usr/bin/env bash

# Exit on any error
set -e

echo "Starting deployment-script-setup.sh"

# Print OS information for debugging
echo "OS Information:"
if [ -f /etc/os-release ]; then
  cat /etc/os-release
elif [ -f /etc/system-release ]; then
  cat /etc/system-release
else
  uname -a
fi

# Function to detect package manager
detect_package_manager() {
  if command -v apt-get &>/dev/null; then
    echo "apt-get"
  elif command -v yum &>/dev/null; then
    echo "yum"
  elif command -v dnf &>/dev/null; then
    echo "dnf"
  elif command -v tdnf &>/dev/null; then
    echo "tdnf"
  elif command -v apk &>/dev/null; then
    echo "apk"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  elif command -v zypper &>/dev/null; then
    echo "zypper"
  else
    echo "unknown"
  fi
}

check_and_install_dependencies() {
  local missing_deps=()

  # Check for git
  if ! command -v git &>/dev/null; then
    missing_deps+=("git")
  fi

  # Check for tar
  if ! command -v tar &>/dev/null; then
    missing_deps+=("tar")
  fi

  # Check for helm
  if ! command -v helm &>/dev/null; then
    missing_deps+=("helm")
  fi

  # If all dependencies are present, return
  if [ ${#missing_deps[@]} -eq 0 ]; then
    echo "All required dependencies are already installed."
    return 0
  fi

  echo "Missing dependencies: ${missing_deps[*]}"

  # Try to install using package manager
  PKG_MANAGER=$(detect_package_manager)
  echo "Detected package manager: $PKG_MANAGER"

  case $PKG_MANAGER in
  apt-get)
    apt-get update
    apt-get install -y "${missing_deps[@]}"
    ;;
  yum)
    yum install -y "${missing_deps[@]}"
    ;;
  dnf)
    dnf install -y "${missing_deps[@]}"
    ;;
  tdnf)
    tdnf install -y "${missing_deps[@]}"
    ;;
  apk)
    apk add --no-cache "${missing_deps[@]}"
    ;;
  pacman)
    pacman -Sy --noconfirm "${missing_deps[@]}"
    ;;
  zypper)
    zypper install -y "${missing_deps[@]}"
    ;;
  *)
    echo "No package manager detected. Attempting alternative installation methods..."

    # Alternative method for git if needed
    if [[ " ${missing_deps[*]} " =~ " git " ]]; then
      echo "Attempting to download and install git manually..."
      mkdir -p /tmp/git_install
      cd /tmp/git_install

      # Try to download a pre-compiled git binary
      curl -L -o git.tar.gz https://github.com/git/git/archive/refs/tags/v2.35.1.tar.gz ||
        wget https://github.com/git/git/archive/refs/tags/v2.35.1.tar.gz -O git.tar.gz

      if [ -f git.tar.gz ]; then
        tar -xzf git.tar.gz
        cd git-*
        # Only try to build if make and gcc are available
        if command -v make &>/dev/null && command -v gcc &>/dev/null; then
          make prefix=/usr/local all
          make prefix=/usr/local install
        else
          echo "Failed to install git: make or gcc not available"
          return 1
        fi
      else
        echo "Failed to download git source"
        return 1
      fi
    fi

    # For tar, it's usually pre-installed on most systems
    if [[ " ${missing_deps[*]} " =~ " tar " ]]; then
      echo "tar is a fundamental utility and should be available. Please install it manually."
      return 1
    fi
    ;;
  esac

  # Verify installation
  for dep in "${missing_deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      echo "Failed to install $dep"
      return 1
    fi
  done

  return 0
}

# Check and install dependencies
if ! check_and_install_dependencies; then
  echo "Failed to install required dependencies. Please install git and tar manually."
  exit 1
fi

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client

echo "Setup complete. kubectl and helm have been installed."
