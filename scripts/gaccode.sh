#!/usr/bin/env bash
# gaccode CLI - 查询余额 / 触发重置
# 用法: gaccode.sh <balance|refill>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TOKEN_FILE="$ROOT_DIR/.gaccode_oauth_token"
ENV_FILE="$ROOT_DIR/.env"

# 读取 .env 配置（环境变量优先，.env 作为回退）
if [[ -f "$ENV_FILE" ]]; then
  while IFS='=' read -r key value; do
    [[ "$key" =~ ^#|^$ ]] && continue
    [[ -z "${!key+x}" ]] && export "$key=$value"
  done < "$ENV_FILE"
fi

BASE_URL="${GACCODE_BASE_URL:-https://gaccode.com}"
EMAIL="${GACCODE_EMAIL:-}"
PASSWORD="${GACCODE_PASSWORD:-}"

# 从系统读取时区，回退到 Asia/Shanghai
if [[ -f /etc/timezone ]]; then
  TZ=$(cat /etc/timezone)
elif [[ -L /etc/localtime ]]; then
  TZ=$(readlink /etc/localtime | sed 's|.*/zoneinfo/||')
else
  TZ="Asia/Shanghai"
fi
export TZ

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
  local response
  response=$(curl -sf "$BASE_URL/api/credits/balance" \
    -H "Authorization: Bearer $token")
  
  # 转换 lastRefill 时间戳到本地时区
  local last_refill_utc
  last_refill_utc=$(echo "$response" | jq -r '.lastRefill')
  
  local last_refill_local
  if [[ -n "$last_refill_utc" && "$last_refill_utc" != "null" ]]; then
    last_refill_local=$(TZ="$TZ" date -d "$last_refill_utc" '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || echo "$last_refill_utc")
  else
    last_refill_local="N/A"
  fi
  
  # 输出格式化结果
  echo "$response" | jq \
    --arg tz "$TZ" \
    --arg last_refill_local "$last_refill_local" \
    '{
      balance: .balance,
      creditCap: .creditCap,
      refillRate: .refillRate,
      lastRefill_UTC: .lastRefill,
      lastRefill_Local: $last_refill_local,
      timezone: $tz
    }'
}

# 子命令：触发重置
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
    echo "重置成功：$support_msg"
  else
    echo "重置失败：$support_msg"
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
