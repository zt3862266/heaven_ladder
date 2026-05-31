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

PANEL_PORT="${PANEL_PORT:-8000}"
PUBLIC_IP="$(get_public_ip)"

log_info "=== Marzban 安装完成 ==="
echo ""
echo "  面板地址: http://${PUBLIC_IP}:${PANEL_PORT}/dashboard"
echo "  默认账号: admin"
echo "  默认密码: admin"
echo ""
echo "  首次登录后请立即修改密码！"
echo ""
echo "  下一步: sudo bash scripts/configure-reality-inbound.sh"
echo ""
