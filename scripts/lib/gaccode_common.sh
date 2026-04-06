#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
ENV_FILE="$ROOT_DIR/.env"
DEFAULT_BASE_URL="https://gaccode.com"
ACTIVE_SUBSCRIPTION_PATH="/api/subscriptions/active"

BASE_URL=""
EMAIL=""
PASSWORD=""
TOKEN=""

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
  local response token payload
  payload=$(jq -n --arg e "$EMAIL" --arg p "$PASSWORD" '{email: $e, password: $p}')
  response=$(api_post "/api/login" "" "$payload")
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

get_active_subscription() {
  local token="$1"

  api_get "$ACTIVE_SUBSCRIPTION_PATH" "$token"
}

format_balance_summary() {
  jq -r '
    "Balance: \(.balance // 0)\nCredit Cap: \(.creditCap // 0)\nBalance Ratio: \((.balanceRatio // 0) | tostring)"
  '
}

format_subscription_summary() {
  jq -r '
    def normalize_iso8601:
      if type == "string" then sub("\\.[0-9]+Z$"; "Z") else . end;
    def remaining_text($end_date):
      if ($end_date | type) != "string" or ($end_date | length) == 0 then
        "N/A"
      else
        (($end_date | normalize_iso8601 | fromdateiso8601) - now) as $seconds
        | if $seconds <= 0 then
            "Expired"
          else
            ($seconds / 86400 | floor) as $days
            | (($seconds % 86400) / 3600 | floor) as $hours
            | (($seconds % 3600) / 60 | floor) as $minutes
            | if $days > 0 then
                "\($days)d \($hours)h \($minutes)m"
              elif $hours > 0 then
                "\($hours)h \($minutes)m"
              else
                "\($minutes)m"
              end
          end
      end;
    .subscriptions[0] as $subscription
    | if $subscription == null then
        "Subscription Tier: None\nSubscription End Date: N/A\nSubscription Time Remaining: N/A"
      else
        "Subscription Tier: \($subscription.subscription.tier // "Unknown")\nSubscription End Date: \($subscription.endDate // "N/A")\nSubscription Time Remaining: \(remaining_text($subscription.endDate))"
      end
  '
}
