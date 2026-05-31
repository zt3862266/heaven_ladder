#!/usr/bin/env bash
# 安装 Marzban 主控面板
# 用法: sudo bash scripts/install-marzban-master.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

require_root
load_env
check_os_supported

log_info "=== 安装 Marzban 主控 ==="

# 安装 Docker（Marzban 脚本会自动处理，但先确保 curl 可用）
if ! command -v docker &>/dev/null; then
  log_info "安装 Docker..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker
  systemctl start docker
fi

# 官方一键安装
log_info "运行 Marzban 官方安装脚本..."
bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install

PUBLIC_IP="${MASTER_IP:-$(get_public_ip)}"
PANEL_PROXY_PORT="${PANEL_PROXY_PORT:-8080}"

log_info "=== Marzban 安装完成 ==="
echo ""
echo "  本机面板（仅服务器上）: http://127.0.0.1:8000/dashboard/"
echo ""
echo "  新版 Marzban 无默认 admin/admin，请创建管理员:"
echo "    sudo marzban cli admin create --sudo"
echo "    或: sudo marzban cli admin import-from-env"
echo ""
echo "  公网面板/订阅（部署流程会自动配置）:"
echo "    sudo bash scripts/setup-panel-proxy.sh"
echo "    → http://${PUBLIC_IP}:${PANEL_PROXY_PORT}/dashboard/"
echo ""
echo "  下一步:"
echo "    sudo bash scripts/configure-reality-inbound.sh"
echo "    sudo bash scripts/setup-panel-proxy.sh"
echo ""
echo "  说明见: docs/panel-and-subscription.md"
echo ""
