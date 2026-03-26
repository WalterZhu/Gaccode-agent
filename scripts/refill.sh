#!/usr/bin/env bash
# 触发 gaccode 积分充值

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TOOLS_FILE="$ROOT_DIR/TOOLS.md"

source "$SCRIPT_DIR/_auth.sh"

gaccode_base_url=$(grep -oP '(?<=gaccode_base_url: ).*' "$TOOLS_FILE" | tr -d '[:space:]')
gaccode_base_url="${gaccode_base_url:-https://gaccode.com}"

token=$(get_token)

response=$(curl -sf -X POST "$gaccode_base_url/api/ticket" \
  -H "Authorization: Bearer $token")

if [[ $? -ne 0 ]]; then
  echo "充值失败" >&2
  exit 1
fi

echo "充值成功：$response"
