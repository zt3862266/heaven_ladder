#!/usr/bin/env bash
# 安装 Hysteria2 作为第二协议备用
# 用法: sudo bash scripts/setup-hysteria2.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

require_root
load_env

HY2_PORT="${HY2_PORT:-8443}"
HY2_PASSWORD="${HY2_PASSWORD:-$(openssl rand -base64 32)}"
PUBLIC_IP="$(get_public_ip)"

log_info "=== 安装 Hysteria2 备用协议 ==="

# 安装 Hysteria2
if ! command -v hysteria &>/dev/null; then
  log_info "下载 Hysteria2..."
  bash <(curl -fsSL https://get.hy2.sh/)
fi

# 自签证书（Hysteria2 需要 TLS）
CERT_DIR="/etc/hysteria"
mkdir -p "${CERT_DIR}"
if [[ ! -f "${CERT_DIR}/cert.pem" ]]; then
  openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
    -keyout "${CERT_DIR}/key.pem" -out "${CERT_DIR}/cert.pem" \
    -days 3650 -subj "/CN=www.microsoft.com"
fi

cat > /etc/hysteria/config.yaml <<EOF
listen: :${HY2_PORT}

tls:
  cert: ${CERT_DIR}/cert.pem
  key: ${CERT_DIR}/key.pem

auth:
  type: password
  password: ${HY2_PASSWORD}

masquerade:
  type: proxy
  proxy:
    url: https://www.microsoft.com
    rewriteHost: true

bandwidth:
  up: 100 mbps
  down: 100 mbps
EOF

# systemd 服务
cat > /etc/systemd/system/hysteria-server.service <<EOF
[Unit]
Description=Hysteria2 Server
After=network.target

[Service]
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hysteria-server
systemctl restart hysteria-server

# 防火墙
ufw allow "${HY2_PORT}"/udp comment 'Hysteria2' 2>/dev/null || true

# 保存配置
HY2_ENV="${PROJECT_ROOT}/config/generated-hysteria2.env"
cat > "${HY2_ENV}" <<EOF
HY2_PORT=${HY2_PORT}
HY2_PASSWORD=${HY2_PASSWORD}
HY2_SERVER=${PUBLIC_IP}
EOF
chmod 600 "${HY2_ENV}"

log_info "=== Hysteria2 安装完成 ==="
echo ""
echo "  服务器: ${PUBLIC_IP}:${HY2_PORT}"
echo "  密码:     ${HY2_PASSWORD}"
echo "  配置:     ${HY2_ENV}"
echo ""
echo "  在 Marzban 面板中为该节点添加 Hysteria2 inbound，或在客户端手动添加备用节点"
echo ""
