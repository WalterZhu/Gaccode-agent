#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/gaccode_common.sh"

cmd_balance() {
  local token balance_with_ratio active_subscription

  token=$(get_token)
  balance_with_ratio=$(get_balance_with_ratio "$token")
  active_subscription=$(get_active_subscription "$token" || true)

  cat <<EOF
Balance check completed.
$(echo "$balance_with_ratio" | format_balance_summary)
$(if [[ -n "$active_subscription" ]]; then echo "$active_subscription" | format_subscription_summary; else echo "Subscription Tier: Unavailable"; echo "Subscription End Date: Unavailable"; fi)
EOF
}

require_bin curl
require_bin jq
load_env_config
cmd_balance
