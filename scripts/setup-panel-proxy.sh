#!/usr/bin/env bash
# 通过 Nginx 在公网端口反代 Marzban（本机 127.0.0.1:8000）
# Marzban 无 SSL 时强制只监听 127.0.0.1，不能直接改 UVICORN_HOST=0.0.0.0
# 用法: sudo bash scripts/setup-panel-proxy.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

require_root
load_env
check_os_supported

PANEL_PROXY_PORT="${PANEL_PROXY_PORT:-8080}"
MARZBAN_UVICORN_PORT="${PANEL_PORT:-8000}"
PUBLIC_IP="${MASTER_IP:-$(get_public_ip)}"
NGINX_SITE="heaven-ladder-marzban-public"
MARZBAN_ENV="/opt/marzban/.env"

log_info "=== 配置面板/订阅公网访问 (Nginx :${PANEL_PROXY_PORT}) ==="

if [[ "${PUBLIC_IP}" == "unknown" ]]; then
  log_error "无法获取公网 IP，请在 .env 中设置 MASTER_IP"
  exit 1
fi

apt-get install -y -qq nginx

# 移除可能冲突的 listen 8000 站点
for f in /etc/nginx/sites-enabled/*; do
  [[ -f "$f" ]] || continue
  if grep -q "listen.*8000" "$f" 2>/dev/null; then
    log_warn "禁用占用 8000 的 Nginx 站点: $f"
    rm -f "$f"
  fi
done

cat > "/etc/nginx/sites-available/${NGINX_SITE}" <<EOF
# Heaven Ladder - Marzban 面板/订阅反代（勿与 Marzban 争抢 8000 端口）
server {
    listen ${PANEL_PROXY_PORT};
    listen [::]:${PANEL_PROXY_PORT};
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:${MARZBAN_UVICORN_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf "/etc/nginx/sites-available/${NGINX_SITE}" "/etc/nginx/sites-enabled/${NGINX_SITE}"
nginx -t
systemctl enable nginx
systemctl reload nginx

ufw allow "${PANEL_PROXY_PORT}/tcp" comment 'Marzban panel/sub via nginx' 2>/dev/null || true

if [[ -f "${MARZBAN_ENV}" ]]; then
  PREFIX="http://${PUBLIC_IP}:${PANEL_PROXY_PORT}"
  if grep -qE '^[[:space:]]*#?[[:space:]]*XRAY_SUBSCRIPTION_URL_PREFIX' "${MARZBAN_ENV}"; then
    sed -i "s|^[[:space:]]*#\\?[[:space:]]*XRAY_SUBSCRIPTION_URL_PREFIX.*|XRAY_SUBSCRIPTION_URL_PREFIX = \"${PREFIX}\"|" "${MARZBAN_ENV}"
  else
    echo "XRAY_SUBSCRIPTION_URL_PREFIX = \"${PREFIX}\"" >> "${MARZBAN_ENV}"
  fi
  log_info "已设置 ${MARZBAN_ENV} → XRAY_SUBSCRIPTION_URL_PREFIX=${PREFIX}"
  marzban restart 2>/dev/null || log_warn "请手动执行: marzban restart"
fi

log_info "=== 完成 ==="
echo ""
echo "  面板:     http://${PUBLIC_IP}:${PANEL_PROXY_PORT}/dashboard/"
echo "  订阅示例: http://${PUBLIC_IP}:${PANEL_PROXY_PORT}/sub/<token>/clash-meta"
echo ""
echo "  请在阿里云安全组放行 TCP ${PANEL_PROXY_PORT}"
echo "  代理流量仍走 TCP 443 (REALITY)，与 ${PANEL_PROXY_PORT} 无关"
echo ""
