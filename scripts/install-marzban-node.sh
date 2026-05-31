#!/usr/bin/env bash
# 安装 Marzban Worker 节点
# 用法: sudo bash scripts/install-marzban-node.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

require_root
check_os_supported

log_info "=== 安装 Marzban Worker 节点 ==="

if ! command -v docker &>/dev/null; then
  log_info "安装 Docker..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker
  systemctl start docker
fi

log_info "运行 Marzban Node 官方安装脚本..."
bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban-node.sh)" @ install

PUBLIC_IP="$(get_public_ip)"

# 确保 SSL_CLIENT_CERT_FILE 已启用
COMPOSE_FILE="${HOME}/Marzban-node/docker-compose.yml"
if [[ -f "${COMPOSE_FILE}" ]]; then
  if grep -q '#.*SSL_CLIENT_CERT_FILE' "${COMPOSE_FILE}"; then
    sed -i 's/#.*SSL_CLIENT_CERT_FILE/      SSL_CLIENT_CERT_FILE/' "${COMPOSE_FILE}"
    log_info "已启用 SSL_CLIENT_CERT_FILE"
  fi
fi

echo ""
log_info "=== Marzban Node 安装完成 ==="
echo ""
echo "  节点公网 IP: ${PUBLIC_IP}"
echo ""
echo "  下一步（在主控 Marzban 面板操作）:"
echo ""
echo "  1. 面板 → Node Settings → Add New Marzban Node"
echo "  2. 填写:"
echo "     - Name:     节点名称（如 sg-primary）"
echo "     - Address:  ${PUBLIC_IP}"
echo "     - Port:     62050"
echo "  3. 复制面板生成的 Certificate"
echo "  4. 在本节点执行:"
echo "     nano /var/lib/marzban-node/ssl_client_cert.pem"
echo "     粘贴 Certificate 内容并保存"
echo "  5. 重启节点:"
echo "     cd ~/Marzban-node && docker compose up -d"
echo "  6. 回到面板确认节点状态为 Connected"
echo ""
echo "  注意: 每个 Worker 节点需要独立配置 REALITY inbound（不同 privateKey/shortId）"
echo "  在主控面板 → Node Settings → 选中节点 → 配置 Core Settings"
echo ""
