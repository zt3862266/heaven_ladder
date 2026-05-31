#!/usr/bin/env bash
# shellcheck disable=SC1091
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

log_info()  { echo "[INFO]  $*"; }
log_warn()  { echo "[WARN]  $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    log_error "请使用 root 运行: sudo bash $0"
    exit 1
  fi
}

load_env() {
  if [[ -f "${PROJECT_ROOT}/.env" ]]; then
    # shellcheck disable=SC2046
    export $(grep -v '^#' "${PROJECT_ROOT}/.env" | grep -v '^\s*$' | xargs)
  else
    log_warn "未找到 ${PROJECT_ROOT}/.env，使用默认值"
  fi
}

detect_os() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_VERSION="${VERSION_ID:-unknown}"
  else
    OS_ID="unknown"
    OS_VERSION="unknown"
  fi
}

check_os_supported() {
  detect_os
  case "${OS_ID}" in
    ubuntu|debian) log_info "系统: ${OS_ID} ${OS_VERSION}" ;;
    *)
      log_error "不支持的操作系统: ${OS_ID}。请使用 Ubuntu 22.04 或 Debian 12"
      exit 1
      ;;
  esac
}

random_hex() {
  local bytes="${1:-8}"
  openssl rand -hex "${bytes}"
}

get_public_ip() {
  curl -fsSL --max-time 5 https://api.ipify.org 2>/dev/null \
    || curl -fsSL --max-time 5 https://ifconfig.me 2>/dev/null \
    || echo "unknown"
}
