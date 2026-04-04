#!/usr/bin/env bash
# refill CLI - 触发重置（包含余额检查）
# 用法: refill.sh [--force]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/gaccode_common.sh"

REFILL_THRESHOLD="0.05"
FORCE_MODE="false"

parse_args() {
  case "${1:-}" in
    "")
      ;;
    --force)
      FORCE_MODE="true"
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
}

should_refill() {
  jq -r --arg threshold "$REFILL_THRESHOLD" '
    if (.creditCap // 0) > 0 and ((.balance // 0) / .creditCap) < ($threshold | tonumber)
    then "true"
    else "false"
    end
  '
}

submit_refill() {
  local token="$1"

  api_post \
    "/api/tickets" \
    "$token" \
    '{"categoryId":3,"title":"请求重置积分","description":"","language":"zh"}'
}

cmd_refill() {
  local token balance_with_ratio support_msg balance_after response refill_needed

  token=$(get_token)
  balance_with_ratio=$(get_balance_with_ratio "$token")
  refill_needed=$(echo "$balance_with_ratio" | should_refill)

  if [[ "$FORCE_MODE" != "true" && "$refill_needed" != "true" ]]; then
    cat <<EOF
Refill not required.
$(echo "$balance_with_ratio" | format_balance_summary)
Threshold: $REFILL_THRESHOLD
Forced: false
EOF
    return 0
  fi

  response=$(submit_refill "$token")
  support_msg=$(echo "$response" | jq -r '.ticket.messages[]? | select(.isFromSupport == true) | .message' | head -1)

  if [[ "$support_msg" == *"已重置"* ]]; then
    balance_after=$(get_balance_with_ratio "$token" || true)
    cat <<EOF
Refill succeeded.
Message: $support_msg
Threshold: $REFILL_THRESHOLD
Forced: $FORCE_MODE
Balance Before:
$(echo "$balance_with_ratio" | format_balance_summary)
Balance After:
$(if [[ -n "$balance_after" ]]; then echo "$balance_after" | format_balance_summary; else echo "Unavailable"; fi)
EOF
  else
    cat <<EOF
Refill failed.
Message: 请登录gaccode网站查看
Threshold: $REFILL_THRESHOLD
Forced: $FORCE_MODE
Balance Before:
$(echo "$balance_with_ratio" | format_balance_summary)
EOF
    exit 1
  fi
}

require_bin curl
require_bin jq
parse_args "${1:-}"
load_env_config
cmd_refill
