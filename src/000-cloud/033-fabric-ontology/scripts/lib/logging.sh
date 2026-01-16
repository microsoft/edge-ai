#!/usr/bin/env bash
# Logging Library - Consistent logging utilities for deployment scripts
#
# Usage:
#   source ./lib/logging.sh
#   log "Section Header"
#   info "Informational message"
#   warn "Warning message"
#   err "Error message"  # exits with code 1

# Colors (if terminal supports it)
if [[ -t 2 ]]; then
  readonly RED='\033[0;31m'
  readonly YELLOW='\033[0;33m'
  readonly GREEN='\033[0;32m'
  readonly BLUE='\033[0;34m'
  readonly NC='\033[0m' # No Color
else
  readonly RED=''
  readonly YELLOW=''
  readonly GREEN=''
  readonly BLUE=''
  readonly NC=''
fi

# Log a section header
log() {
  echo -e "${BLUE}========== $1 ==========${NC}" >&2
}

# Log informational message
info() {
  echo -e "[ ${GREEN}INFO${NC} ]: $1" >&2
}

# Log warning message
warn() {
  echo -e "[ ${YELLOW}WARN${NC} ]: $1" >&2
}

# Log error message and exit
err() {
  echo -e "[ ${RED}ERROR${NC} ]: $1" >&2
  exit 1
}

# Log success message
ok() {
  echo -e "[ ${GREEN}OK${NC}    ]: $1" >&2
}

# Log debug message (only if DEBUG is set)
debug() {
  if [[ -n "${DEBUG:-}" ]]; then
    echo -e "[ DEBUG ]: $1" >&2
  fi
}
