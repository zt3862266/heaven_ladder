#!/usr/bin/env bash
# 系统基线：BBR、防火墙、自动安全更新
# 用法: sudo bash scripts/system-baseline.sh [--skip-panel-port]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

require_root
load_env
check_os_supported

SKIP_PANEL_PORT=false
if [[ "${1:-}" == "--skip-panel-port" ]]; then
  SKIP_PANEL_PORT=true
fi

PANEL_PORT="${PANEL_PORT:-8000}"
ADMIN_IP="${ADMIN_WHITELIST_IP:-}"

log_info "=== Heaven Ladder 系统基线配置 ==="

# ── 1. 系统更新 ──
log_info "更新系统包..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq

# ── 2. 安装基础工具 ──
apt-get install -y -qq curl wget git ufw unattended-upgrades openssl

# ── 3. 开启 BBR ──
log_info "配置 BBR 拥塞控制..."
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf 2>/dev/null; then
  cat >> /etc/sysctl.conf <<'EOF'

# Heaven Ladder - BBR
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
  sysctl -p
  log_info "BBR 已启用"
else
  log_info "BBR 已存在，跳过"
fi

# ── 4. 自动安全更新 ──
log_info "配置 unattended-upgrades..."
dpkg-reconfigure -plow unattended-upgrades 2>/dev/null || true

# ── 5. UFW 防火墙 ──
log_info "配置 UFW 防火墙..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 443/tcp comment 'VLESS REALITY'

if [[ "${SKIP_PANEL_PORT}" == "false" && -n "${ADMIN_IP}" ]]; then
  ufw allow from "${ADMIN_IP}" to any port "${PANEL_PORT}" proto tcp comment 'Marzban Panel'
  log_info "面板端口 ${PANEL_PORT} 仅允许 ${ADMIN_IP}"
elif [[ "${SKIP_PANEL_PORT}" == "false" ]]; then
  log_warn "未设置 ADMIN_WHITELIST_IP，面板端口 ${PANEL_PORT} 未开放"
  log_warn "建议: 在 .env 中设置 ADMIN_WHITELIST_IP，或通过 SSH 隧道访问面板"
else
  log_info "Worker 节点模式，跳过面板端口"
fi

ufw --force enable
ufw status verbose

# ── 6. 时区 ──
timedatectl set-timezone Asia/Shanghai 2>/dev/null || true

log_info "=== 系统基线配置完成 ==="
log_info "公网 IP: $(get_public_ip)"
