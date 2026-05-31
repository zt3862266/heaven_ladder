#!/usr/bin/env bash
# 更新 Marzban 及所有节点
# 用法: sudo bash scripts/update-all.sh [--node]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

require_root

IS_NODE=false
[[ "${1:-}" == "--node" ]] && IS_NODE=true

if [[ "${IS_NODE}" == "true" ]]; then
  log_info "更新 Marzban Node..."
  bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban-node.sh)" @ update
else
  log_info "更新 Marzban 主控..."
  bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ update
fi

log_info "更新完成"
