#!/usr/bin/env bash
# gaccode CLI - 查询余额 / 触发充值
# 用法: gaccode.sh <balance|refill>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TOKEN_FILE="$ROOT_DIR/.gaccode_oauth_token.json"
TOOLS_FILE="$ROOT_DIR/TOOLS.md"

# 读取配置
_config() {
  local key="$1"
  local default="${2:-}"
  local val
  val=$(awk -F': ' "/^${key}:/{print \$2}" "$TOOLS_FILE" | tr -d '[:space:]')
  echo "${val:-$default}"
}

BASE_URL=$(_config gaccode_base_url "https://gaccode.com")
EMAIL=$(_config gaccode_email)
PASSWORD=$(_config gaccode_password)

# 检查 token 是否有效
_token_valid() {
  [[ -f "$TOKEN_FILE" ]]
}

# 登录并缓存 token
_login() {
  local response
  response=$(curl -sf -X POST "$BASE_URL/api/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

  local token
  token=$(echo "$response" | jq -r '.token')

  if [[ -z "$token" || "$token" == "null" ]]; then
    echo "登录失败" >&2
    exit 1
  fi

  echo "$token" > "$TOKEN_FILE"
}

# 验证 token 是否仍有效（请求 /api/me）
_verify_token() {
  local token
  token=$(cat "$TOKEN_FILE")
  local response
  response=$(curl -sf "$BASE_URL/api/me" -H "Authorization: Bearer $token" 2>/dev/null) || return 1
  [[ $(echo "$response" | jq -r '.user.id') != "null" ]]
}

# 获取有效 token
_get_token() {
  if ! _token_valid || ! _verify_token; then
    _login
  fi
  cat "$TOKEN_FILE"
}

# 子命令：查询余额
cmd_balance() {
  local token
  token=$(_get_token)
  curl -sf "$BASE_URL/api/credits/balance" \
    -H "Authorization: Bearer $token"
}

# 子命令：触发充值
cmd_refill() {
  local token
  token=$(_get_token)
  local response
  response=$(curl -sf -X POST "$BASE_URL/api/tickets" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d '{"categoryId":3,"title":"请求重置积分","description":"","language":"zh"}')
  local support_msg
  support_msg=$(echo "$response" | jq -r '.ticket.messages[] | select(.isFromSupport==true) | .message' | head -1)
  if [[ "$support_msg" == *"已重置"* ]]; then
    echo "充值成功：$support_msg"
  else
    echo "充值失败：$support_msg"
    exit 1
  fi
}

case "${1:-}" in
  balance) cmd_balance ;;
  refill)  cmd_refill ;;
  *)
    echo "用法: $(basename "$0") <balance|refill>" >&2
    exit 1
    ;;
esac
