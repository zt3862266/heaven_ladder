#!/usr/bin/env bash
# 为 Worker 节点生成独立 REALITY 密钥（每台节点运行一次）
# 用法: sudo bash scripts/generate-reality-keys.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

load_env

REALITY_DEST="${REALITY_DEST:-www.microsoft.com:443}"
REALITY_SERVER_NAME="${REALITY_SERVER_NAME:-www.microsoft.com}"
NODE_NAME="${1:-worker-$(random_hex 2)}"

log_info "=== 为节点 [${NODE_NAME}] 生成 REALITY 密钥 ==="

# 尝试从 Marzban 容器生成
MARZBAN_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i marzban | head -1)

if [[ -n "${MARZBAN_CONTAINER}" ]]; then
  KEYS=$(docker exec "${MARZBAN_CONTAINER}" xray x25519)
  PRIVATE_KEY=$(echo "${KEYS}" | grep -i 'PrivateKey\|Private key' | awk '{print $NF}')
  PUBLIC_KEY=$(echo "${KEYS}" | grep -i 'Password\|Public key' | awk '{print $NF}')
else
  # 独立 xray 或 openssl fallback
  if command -v xray &>/dev/null; then
    KEYS=$(xray x25519)
    PRIVATE_KEY=$(echo "${KEYS}" | head -1 | awk '{print $NF}')
    PUBLIC_KEY=$(echo "${KEYS}" | tail -1 | awk '{print $NF}')
  else
    log_error "未找到 xray，请先安装 Marzban 或 Marzban Node"
    exit 1
  fi
fi

SHORT_ID=$(random_hex 8)
PUBLIC_IP="$(get_public_ip)"

OUTPUT="${PROJECT_ROOT}/config/nodes/${NODE_NAME}-reality.env"
mkdir -p "$(dirname "${OUTPUT}")"

cat > "${OUTPUT}" <<EOF
# 节点: ${NODE_NAME}
# IP: ${PUBLIC_IP}
# 生成时间: $(date -Iseconds)
NODE_NAME=${NODE_NAME}
NODE_IP=${PUBLIC_IP}
REALITY_PRIVATE_KEY=${PRIVATE_KEY}
REALITY_PUBLIC_KEY=${PUBLIC_KEY}
REALITY_SHORT_ID=${SHORT_ID}
REALITY_DEST=${REALITY_DEST}
REALITY_SERVER_NAME=${REALITY_SERVER_NAME}
EOF
chmod 600 "${OUTPUT}"

# 同时生成 inbound JSON
cat > "${PROJECT_ROOT}/config/nodes/${NODE_NAME}-inbound.json" <<EOF
{
  "tag": "VLESS TCP REALITY",
  "listen": "0.0.0.0",
  "port": 443,
  "protocol": "vless",
  "settings": {
    "clients": [],
    "decryption": "none"
  },
  "streamSettings": {
    "network": "tcp",
    "tcpSettings": {},
    "security": "reality",
    "realitySettings": {
      "show": false,
      "dest": "${REALITY_DEST}",
      "xver": 0,
      "serverNames": ["${REALITY_SERVER_NAME}"],
      "privateKey": "${PRIVATE_KEY}",
      "shortIds": ["${SHORT_ID}"]
    }
  },
  "sniffing": {
    "enabled": true,
    "destOverride": ["http", "tls", "quic"]
  }
}
EOF

log_info "密钥已保存:"
echo "  ${OUTPUT}"
echo "  ${PROJECT_ROOT}/config/nodes/${NODE_NAME}-inbound.json"
echo ""
echo "  在主控 Marzban 面板 → Node Settings → 选中该节点 → Core Settings"
echo "  将 inbound JSON 粘贴到 inbounds 数组中，Save → Restart"
echo ""
echo "  PublicKey: ${PUBLIC_KEY}"
echo "  ShortId:   ${SHORT_ID}"
