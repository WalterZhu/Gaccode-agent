#!/usr/bin/env bash
# refill CLI - 触发重置（包含余额检查）
# 用法: refill.sh [--force]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$ROOT_DIR/.env"
DEFAULT_BASE_URL="https://gaccode.com"
REFILL_THRESHOLD="0.05"

BASE_URL=""
EMAIL=""
PASSWORD=""
TOKEN=""
FORCE_MODE="false"

require_bin() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required binary: $1" >&2
    exit 1
  fi
}

trim() {
  local value="${1:-}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "$value"
}

unquote() {
  local value="${1:-}"
  if [[ "$value" =~ ^\"(.*)\"$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  elif [[ "$value" =~ ^\'(.*)\'$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  else
    printf '%s\n' "$value"
  fi
}

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

load_env_config() {
  [[ -f "$ENV_FILE" ]] || {
    echo "缺少配置文件: $ENV_FILE" >&2
    exit 1
  }

  while IFS='=' read -r raw_key raw_value; do
    [[ "$raw_key" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${raw_key//[[:space:]]/}" ]] && continue

    local key value
    key=$(trim "$raw_key")
    value=$(unquote "$(trim "${raw_value:-}")")

    case "$key" in
      GACCODE_BASE_URL) BASE_URL="$value" ;;
      GACCODE_EMAIL) EMAIL="$value" ;;
      GACCODE_PASSWORD) PASSWORD="$value" ;;
      GACCODE_TOKEN) TOKEN="$value" ;;
    esac
  done < "$ENV_FILE"

  [[ -n "$EMAIL" && -n "$PASSWORD" ]] || {
    echo ".env 中缺少必要配置: GACCODE_EMAIL 或 GACCODE_PASSWORD" >&2
    exit 1
  }

  BASE_URL="${BASE_URL:-$DEFAULT_BASE_URL}"
}

set_env_value() {
  local key="$1"
  local value="$2"
  local tmp_file
  tmp_file=$(mktemp "${ENV_FILE}.tmp.XXXXXX")

  awk -v key="$key" -v value="$value" -F'=' '
    BEGIN { updated = 0 }
    {
      raw = $0
      split(raw, parts, "=")
      current_key = parts[1]
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", current_key)

      if (current_key == key) {
        print key "=" value
        updated = 1
      } else {
        print raw
      }
    }
    END {
      if (!updated) {
        print key "=" value
      }
    }
  ' "$ENV_FILE" > "$tmp_file"

  mv "$tmp_file" "$ENV_FILE"
}

api_get() {
  local path="$1"
  local token="${2:-}"

  if [[ -n "$token" ]]; then
    curl -sf "$BASE_URL$path" -H "Authorization: Bearer $token"
  else
    curl -sf "$BASE_URL$path"
  fi
}

api_post() {
  local path="$1"
  local token="$2"
  local payload="$3"

  if [[ -n "$token" ]]; then
    curl -sf -X POST "$BASE_URL$path" \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" \
      -d "$payload"
  else
    curl -sf -X POST "$BASE_URL$path" \
      -H "Content-Type: application/json" \
      -d "$payload"
  fi
}

login() {
  local response token
  response=$(api_post "/api/login" "" "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
  token=$(echo "$response" | jq -r '.token')

  [[ -n "$token" && "$token" != "null" ]] || {
    echo "登录失败" >&2
    exit 1
  }

  TOKEN="$token"
  set_env_value "GACCODE_TOKEN" "$TOKEN"
}

token_valid() {
  [[ -n "$TOKEN" ]] || return 1

  local response
  response=$(api_get "/api/me" "$TOKEN" 2>/dev/null) || return 1
  [[ "$(echo "$response" | jq -r '.user.id')" != "null" ]]
}

get_token() {
  if ! token_valid; then
    login
  fi

  printf '%s\n' "$TOKEN"
}

get_balance_with_ratio() {
  local token="$1"

  api_get "/api/credits/balance" "$token" | jq '
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

should_refill() {
  jq -r --arg threshold "$REFILL_THRESHOLD" '
    if (.creditCap // 0) > 0 and ((.balance // 0) / .creditCap) < ($threshold | tonumber)
    then "true"
    else "false"
    end
  '
}

format_balance_summary() {
  jq -r '
    "Balance: \(.balance // 0)\nCredit Cap: \(.creditCap // 0)\nBalance Ratio: \((.balanceRatio // 0) | tostring)"
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
