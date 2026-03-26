#!/usr/bin/env bash
# 获取有效 token（读取缓存，过期或不存在则重新登录）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TOKEN_FILE="$ROOT_DIR/.gaccode_oauth_token.json"

_need_login() {
  [[ ! -f "$TOKEN_FILE" ]] && return 0
  expires_at=$(jq -r '.expires_at' "$TOKEN_FILE" 2>/dev/null || echo "")
  now=$(date -u "+%Y-%m-%dT%H:%M:%SZ")
  [[ "$now" > "$expires_at" ]] && return 0
  return 1
}

get_token() {
  if _need_login; then
    bash "$SCRIPT_DIR/login.sh" >&2
  fi
  jq -r '.token' "$TOKEN_FILE"
}
