#!/usr/bin/env bash
# refill CLI - 触发重置

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/gaccode_common.sh"

[[ $# -eq 0 ]] || {
  echo "Unknown argument: $1" >&2
  exit 1
}

submit_refill() {
  local token="$1"

  api_post \
    "/api/tickets" \
    "$token" \
    '{"categoryId":3,"title":"请求重置积分","description":"","language":"zh"}'
}

cmd_refill() {
  local token balance_with_ratio support_msg balance_after response

  token=$(get_token)
  balance_with_ratio=$(get_balance_with_ratio "$token")

  response=$(submit_refill "$token")
  support_msg=$(echo "$response" | jq -r '.ticket.messages[]? | select(.isFromSupport == true) | .message' | head -1)

  if [[ "$support_msg" == *"已重置"* ]]; then
    balance_after=$(get_balance_with_ratio "$token" || true)
    cat <<EOF
Refill succeeded.
Message: $support_msg
Balance Before:
$(echo "$balance_with_ratio" | format_balance_summary)
Balance After:
$(if [[ -n "$balance_after" ]]; then echo "$balance_after" | format_balance_summary; else echo "Unavailable"; fi)
EOF
  else
    cat <<EOF
Refill failed.
Message: 请登录gaccode网站查看
Balance Before:
$(echo "$balance_with_ratio" | format_balance_summary)
EOF
    exit 1
  fi
}

require_bin curl
require_bin jq
load_env_config
cmd_refill
