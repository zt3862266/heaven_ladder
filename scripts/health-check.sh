#!/usr/bin/env bash
# 检查所有节点 443 端口连通性
# 用法: bash scripts/health-check.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

load_env

INVENTORY="${PROJECT_ROOT}/config/nodes/inventory.json"
PORT=443
TIMEOUT=5

check_port() {
  local ip="$1" port="$2"
  if timeout "${TIMEOUT}" bash -c "echo >/dev/tcp/${ip}/${port}" 2>/dev/null; then
    echo "OK"
  else
    echo "FAIL"
  fi
}

log_info "=== Heaven Ladder 节点健康检查 ==="
echo ""

# 从 inventory.json 或 .env 读取节点
declare -a NODES=()

if [[ -f "${INVENTORY}" ]]; then
  while IFS= read -r line; do
    NODES+=("${line}")
  done < <(python3 - "${INVENTORY}" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    for n in json.load(f):
        print(f"{n['name']}|{n['ip']}|{n.get('region','')}")
PY
)
else
  [[ -n "${NODE1_IP:-}" ]] && NODES+=("${NODE1_NAME:-node1}|${NODE1_IP}|${NODE1_REGION:-}")
  [[ -n "${NODE2_IP:-}" ]] && NODES+=("${NODE2_NAME:-node2}|${NODE2_IP}|${NODE2_REGION:-}")
  [[ -n "${NODE3_IP:-}" ]] && NODES+=("${NODE3_NAME:-node3}|${NODE3_IP}|${NODE3_REGION:-}")
fi

if [[ ${#NODES[@]} -eq 0 ]]; then
  log_warn "未找到节点配置。请复制 config/nodes/inventory.example.json 为 inventory.json 并填写 IP"
  exit 1
fi

printf "%-20s %-18s %-10s %s\n" "NAME" "IP" "REGION" "443/TCP"
printf "%-20s %-18s %-10s %s\n" "----" "--" "------" "-------"

FAILED=0
for entry in "${NODES[@]}"; do
  IFS='|' read -r name ip region <<< "${entry}"
  status=$(check_port "${ip}" "${PORT}")
  printf "%-20s %-18s %-10s %s\n" "${name}" "${ip}" "${region}" "${status}"
  [[ "${status}" == "FAIL" ]] && FAILED=$((FAILED + 1))
done

echo ""
if [[ ${FAILED} -gt 0 ]]; then
  log_warn "${FAILED} 个节点不可达，请检查安全组/VPS 状态/IP 是否被封"
  exit 1
else
  log_info "所有节点正常"
fi
