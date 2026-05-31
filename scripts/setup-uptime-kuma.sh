#!/usr/bin/env bash
# 部署 Uptime Kuma 节点监控
# 用法: sudo bash scripts/setup-uptime-kuma.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

require_root
load_env

KUMA_PORT="${UPTIME_KUMA_PORT:-3001}"
ADMIN_IP="${ADMIN_WHITELIST_IP:-}"

log_info "=== 部署 Uptime Kuma ==="

if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker && systemctl start docker
fi

docker volume create uptime-kuma 2>/dev/null || true

docker rm -f uptime-kuma 2>/dev/null || true
docker run -d \
  --name uptime-kuma \
  --restart always \
  -p "127.0.0.1:${KUMA_PORT}:3001" \
  -v uptime-kuma:/app/data \
  louislam/uptime-kuma:1

if [[ -n "${ADMIN_IP}" ]]; then
  ufw allow from "${ADMIN_IP}" to any port "${KUMA_PORT}" proto tcp comment 'Uptime Kuma' 2>/dev/null || true
fi

log_info "=== Uptime Kuma 部署完成 ==="
echo ""
echo "  访问地址: http://$(get_public_ip):${KUMA_PORT}"
echo "  首次访问需创建管理员账号"
echo ""
echo "  建议添加以下 Monitor（Type: Port）:"
echo "    - 各节点 443/tcp（REALITY）"
echo "    - 各节点 8443/udp（Hysteria2，如有）"
echo ""
if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
  echo "  Telegram 通知: 在 Settings → Notifications 中配置 Bot Token 和 Chat ID"
fi
echo ""
