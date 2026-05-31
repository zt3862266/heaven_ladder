#!/usr/bin/env bash
# 配置 VLESS + REALITY + XTLS-Vision inbound
# 用法: sudo bash scripts/configure-reality-inbound.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

require_root
load_env

REALITY_DEST="${REALITY_DEST:-www.microsoft.com:443}"
REALITY_SERVER_NAME="${REALITY_SERVER_NAME:-www.microsoft.com}"
PUBLIC_IP="${MASTER_IP:-$(get_public_ip)}"

log_info "=== 配置 VLESS REALITY Inbound ==="

# 找到 Marzban 容器
MARZBAN_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i marzban | grep -v node | head -1)
if [[ -z "${MARZBAN_CONTAINER}" ]]; then
  log_error "未找到 Marzban 容器，请先运行 install-marzban-master.sh"
  exit 1
fi
log_info "Marzban 容器: ${MARZBAN_CONTAINER}"

# 生成 REALITY 密钥
log_info "生成 x25519 密钥对..."
KEYS=$(docker exec "${MARZBAN_CONTAINER}" xray x25519)
PRIVATE_KEY=$(echo "${KEYS}" | grep -i 'PrivateKey\|Private key' | awk '{print $NF}')
PUBLIC_KEY=$(echo "${KEYS}" | grep -i 'Password\|Public key' | awk '{print $NF}')

if [[ -z "${PRIVATE_KEY}" || -z "${PUBLIC_KEY}" ]]; then
  # xray 版本不同，输出格式可能不同，尝试另一种解析
  PRIVATE_KEY=$(echo "${KEYS}" | head -1 | awk '{print $NF}')
  PUBLIC_KEY=$(echo "${KEYS}" | tail -1 | awk '{print $NF}')
fi

SHORT_ID=$(random_hex 8)
log_info "PrivateKey: ${PRIVATE_KEY:0:16}..."
log_info "PublicKey:  ${PUBLIC_KEY:0:16}..."
log_info "ShortId:    ${SHORT_ID}"

# 保存密钥到本地（供备份）
KEYS_FILE="${PROJECT_ROOT}/config/generated-keys.env"
mkdir -p "$(dirname "${KEYS_FILE}")"
cat > "${KEYS_FILE}" <<EOF
# 生成时间: $(date -Iseconds)
# 请妥善保管，勿提交到 Git
REALITY_PRIVATE_KEY=${PRIVATE_KEY}
REALITY_PUBLIC_KEY=${PUBLIC_KEY}
REALITY_SHORT_ID=${SHORT_ID}
REALITY_DEST=${REALITY_DEST}
REALITY_SERVER_NAME=${REALITY_SERVER_NAME}
EOF
chmod 600 "${KEYS_FILE}"
log_info "密钥已保存到 ${KEYS_FILE}"

# 生成 inbound JSON 片段
INBOUND_FILE="${PROJECT_ROOT}/config/marzban/reality-inbound.generated.json"
mkdir -p "$(dirname "${INBOUND_FILE}")"
cat > "${INBOUND_FILE}" <<EOF
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

echo ""
log_info "=== REALITY Inbound 配置已生成 ==="
echo ""
echo "  配置文件: ${INBOUND_FILE}"
echo ""
echo "  请按以下步骤在 Marzban 面板中完成配置:"
echo ""
echo "  1. 登录面板 → Settings → Core Settings"
echo "  2. 在 inbounds 数组的 [ 后面，粘贴 reality-inbound.generated.json 的内容"
echo "  3. 点击 Save → Restart Core"
echo "  4. Settings → Hosts → VLESS TCP REALITY 仅保留一条 Host:"
echo "       Address = ${PUBLIC_IP:-<主控公网IP>}  高级: Port=443, SNI=${REALITY_SERVER_NAME}"
echo "       删除空白 Host；不用 SS 则清理 Shadowsocks TCP 的 Host"
echo "  5. Users → Vless → 右侧 ⋮ → Flow=xtls-rprx-vision；仅勾选 Vless"
echo "  6. 公网订阅: http://<IP>:8080/sub/<token>/clash-meta （见 setup-panel-proxy.sh）"
echo ""
echo "  PublicKey (客户端需要): ${PUBLIC_KEY}"
echo "  ShortId:                ${SHORT_ID}"
echo "  ServerName:             ${REALITY_SERVER_NAME}"
echo ""

# 尝试自动写入 Marzban xray config（如果路径存在）
XRAY_CONFIG="/var/lib/marzban/xray_config.json"
if [[ -f "${XRAY_CONFIG}" ]]; then
  log_info "检测到 ${XRAY_CONFIG}，尝试自动合并 inbound..."

  python3 - "${XRAY_CONFIG}" "${INBOUND_FILE}" <<'PYEOF'
import json, sys

config_path, inbound_path = sys.argv[1], sys.argv[2]
with open(config_path) as f:
    config = json.load(f)
with open(inbound_path) as f:
    new_inbound = json.load(f)

tag = new_inbound["tag"]
inbounds = config.get("inbounds", [])
config["inbounds"] = [ib for ib in inbounds if ib.get("tag") != tag]
config["inbounds"].insert(0, new_inbound)

with open(config_path, "w") as f:
    json.dump(config, f, indent=2)
print("OK")
PYEOF

  if [[ $? -eq 0 ]]; then
    log_info "已自动写入 xray_config.json，正在重启 Marzban..."
    marzban restart 2>/dev/null || docker restart "${MARZBAN_CONTAINER}"
    log_info "Core 已重启"
  fi
else
  log_warn "未找到 ${XRAY_CONFIG}，请手动在面板中配置"
fi
