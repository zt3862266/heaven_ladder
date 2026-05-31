#!/usr/bin/env bash
# Heaven Ladder 一键部署入口
# 用法:
#   sudo bash deploy.sh master    # 主控节点完整部署（含面板反代）
#   sudo bash deploy.sh panel-proxy  # 仅配置 Nginx 公网面板/订阅
#   sudo bash deploy.sh node      # Worker 节点部署
#   sudo bash deploy.sh extras    # Hysteria2 + Uptime Kuma
#   bash deploy.sh check          # 健康检查
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Heaven Ladder 部署工具

用法: bash deploy.sh <command>

命令:
  master       主控节点完整部署（基线 + Marzban + REALITY + 面板反代）
  panel-proxy  配置 Nginx 公网访问面板/订阅（8080→127.0.0.1:8000）
  node         Worker 节点部署（基线 + Marzban Node）
  extras    可选组件（Hysteria2 + Uptime Kuma）
  check     节点健康检查
  update    更新 Marzban / Marzban Node

示例:
  sudo bash deploy.sh master
  sudo bash deploy.sh panel-proxy
  sudo bash deploy.sh node
EOF
}

cmd="${1:-}"
case "${cmd}" in
  master)
    bash "${SCRIPT_DIR}/scripts/system-baseline.sh"
    bash "${SCRIPT_DIR}/scripts/install-marzban-master.sh"
    bash "${SCRIPT_DIR}/scripts/configure-reality-inbound.sh"
    bash "${SCRIPT_DIR}/scripts/setup-panel-proxy.sh"
    ;;
  panel-proxy)
    bash "${SCRIPT_DIR}/scripts/setup-panel-proxy.sh"
    ;;
  node)
    bash "${SCRIPT_DIR}/scripts/system-baseline.sh" --skip-panel-port
    bash "${SCRIPT_DIR}/scripts/install-marzban-node.sh"
    ;;
  extras)
    bash "${SCRIPT_DIR}/scripts/setup-hysteria2.sh"
    bash "${SCRIPT_DIR}/scripts/setup-uptime-kuma.sh"
    ;;
  check)
    bash "${SCRIPT_DIR}/scripts/health-check.sh"
    ;;
  update)
    bash "${SCRIPT_DIR}/scripts/update-all.sh" "${2:-}"
    ;;
  *)
    usage
    exit 1
    ;;
esac
