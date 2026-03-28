#!/usr/bin/env bash
# gaccode CLI - 触发重置（包含余额检查）
# 用法: gaccode.sh [force]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TOKEN_FILE="$ROOT_DIR/.gaccode_oauth_token"
ENV_FILE="$ROOT_DIR/.env"

BASE_URL="https://gaccode.com"
EMAIL=""
PASSWORD=""

# 仅从 .env 读取配置，不读取当前 shell 环境变量
_load_env_config() {
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "缺少配置文件: $ENV_FILE" >&2
    exit 1
  fi

  while IFS='=' read -r raw_key raw_value; do
    [[ "$raw_key" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${raw_key//[[:space:]]/}" ]] && continue

    local key value
    key=$(echo "$raw_key" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    value=$(echo "${raw_value:-}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

    if [[ "$value" =~ ^\"(.*)\"$ ]]; then
      value="${BASH_REMATCH[1]}"
    elif [[ "$value" =~ ^\'(.*)\'$ ]]; then
      value="${BASH_REMATCH[1]}"
    fi

    case "$key" in
      GACCODE_BASE_URL) BASE_URL="${value:-https://gaccode.com}" ;;
      GACCODE_EMAIL) EMAIL="$value" ;;
      GACCODE_PASSWORD) PASSWORD="$value" ;;
    esac
  done < "$ENV_FILE"

  if [[ -z "$EMAIL" || -z "$PASSWORD" ]]; then
    echo ".env 中缺少必要配置: GACCODE_EMAIL 或 GACCODE_PASSWORD" >&2
    exit 1
  fi
}

_load_env_config

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

# 获取余额并附加 balanceRatio
_get_balance_with_ratio() {
  local token="$1"
  local balance_response
  balance_response=$(curl -sf "$BASE_URL/api/credits/balance" \
    -H "Authorization: Bearer $token")

  echo "$balance_response" | jq '
    . + {
      balanceRatio: (
        if (.creditCap // 0) > 0
        then ((.balance // 0) / .creditCap)
        else 0
        end
      )
    }
  '
}

# 执行重置（force=true 时跳过阈值检查）
cmd_refill() {
  local force_mode="${1:-false}"
  local token
  token=$(_get_token)

  local balance_with_ratio
  balance_with_ratio=$(_get_balance_with_ratio "$token")

  local should_refill
  should_refill=$(echo "$balance_with_ratio" | jq -r '
    if (.creditCap // 0) > 0 and ((.balance // 0) / .creditCap) < 0.05
    then "true"
    else "false"
    end
  ')

  if [[ "$force_mode" != "true" && "$should_refill" != "true" ]]; then
    echo "$balance_with_ratio" | jq '
      . + {
        action: "skip_refill",
        reason: "balance_ratio_not_below_threshold",
        refillThreshold: 0.05,
        forced: false
      }
    '
    return 0
  fi

  local response
  response=$(curl -sf -X POST "$BASE_URL/api/tickets" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d '{"categoryId":3,"title":"请求重置积分","description":"","language":"zh"}')
  local support_msg
  support_msg=$(echo "$response" | jq -r '.ticket.messages[]? | select(.isFromSupport==true) | .message' | head -1)
  if [[ "$support_msg" == *"已重置"* ]]; then
    local balance_after
    balance_after=$(_get_balance_with_ratio "$token" || echo "null")
    jq -n \
      --argjson balanceBefore "$balance_with_ratio" \
      --argjson balanceAfter "$balance_after" \
      --arg message "$support_msg" \
      --argjson forced "$force_mode" \
      '{
        action: "refill",
        status: "success",
        refillThreshold: 0.05,
        forced: $forced,
        message: $message,
        balanceBefore: $balanceBefore,
        balanceAfter: $balanceAfter
      }'
  else
    jq -n \
      --argjson balanceBefore "$balance_with_ratio" \
      --argjson forced "$force_mode" \
      '{
        action: "refill",
        status: "failed",
        refillThreshold: 0.05,
        forced: $forced,
        message: "请登录gaccode网站查看",
        balanceBefore: $balanceBefore
      }'
    exit 1
  fi
}

case "${1:-}" in
  "")
    cmd_refill "false"
    ;;
  force)
    cmd_refill "true"
    ;;
  *)
    echo "用法: $(basename "$0") [force]" >&2
    exit 1
    ;;
esac
