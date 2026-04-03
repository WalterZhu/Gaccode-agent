#!/usr/bin/env bash

set -euo pipefail

DEFAULT_CONFIG_PATH="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"

usage() {
  cat <<'EOF' >&2
Usage:
  scripts/test_provider.sh --provider PROVIDER_NAME [--config PATH]

Overrides:
  scripts/test_provider.sh \
    --base-url URL \
    --api-key KEY \
    --api anthropic-messages|openai-responses \
    --model MODEL_ID

Examples:
  scripts/test_provider.sh --provider custom-claude-code
  scripts/test_provider.sh --provider custom-openai-codex

  scripts/test_provider.sh \
    --config ~/.openclaw/openclaw.json \
    --provider custom-openai-codex

  scripts/test_provider.sh \
    --base-url https://relay03.gaccode.com/codex/v1 \
    --api-key YOUR_API_KEY \
    --api openai-responses \
    --model gpt-5.4
EOF
  exit 1
}

require_bin() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required binary: $1" >&2
    exit 1
  fi
}

CONFIG_PATH="$DEFAULT_CONFIG_PATH"
PROVIDER_NAME=""
BASE_URL=""
API_KEY=""
API_KIND=""
MODEL_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      CONFIG_PATH="${2:-}"
      shift 2
      ;;
    --provider)
      PROVIDER_NAME="${2:-}"
      shift 2
      ;;
    --base-url)
      BASE_URL="${2:-}"
      shift 2
      ;;
    --api-key)
      API_KEY="${2:-}"
      shift 2
      ;;
    --api)
      API_KIND="${2:-}"
      shift 2
      ;;
    --model)
      MODEL_ID="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      ;;
  esac
done

require_bin curl
require_bin jq

resolve_api_key_from_provider() {
  local provider_json="$1"
  local api_key_type
  api_key_type=$(echo "$provider_json" | jq -r '
    if (.apiKey | type) == "string" then
      "string"
    elif (.apiKey | type) == "object" then
      (.apiKey.source // "unsupported")
    else
      "unsupported"
    end
  ')

  case "$api_key_type" in
    string)
      echo "$provider_json" | jq -r '.apiKey'
      ;;
    env)
      local env_name
      env_name=$(echo "$provider_json" | jq -r '.apiKey.id // empty')
      [[ -n "$env_name" ]] || {
        echo "Provider apiKey env source is missing .apiKey.id" >&2
        exit 1
      }
      local env_value="${!env_name:-}"
      [[ -n "$env_value" ]] || {
        echo "Environment variable not set: $env_name" >&2
        exit 1
      }
      printf '%s\n' "$env_value"
      ;;
    file)
      local file_path
      file_path=$(echo "$provider_json" | jq -r '.apiKey.path // empty')
      [[ -n "$file_path" ]] || {
        echo "Provider apiKey file source is missing .apiKey.path" >&2
        exit 1
      }
      [[ -f "$file_path" ]] || {
        echo "API key file not found: $file_path" >&2
        exit 1
      }
      tr -d '\r\n' < "$file_path"
      ;;
    exec)
      local command_json
      command_json=$(echo "$provider_json" | jq -c '.apiKey.command // empty')
      [[ -n "$command_json" ]] || {
        echo "Provider apiKey exec source is missing .apiKey.command" >&2
        exit 1
      }
      mapfile -t command_parts < <(echo "$command_json" | jq -r '.[]')
      [[ "${#command_parts[@]}" -gt 0 ]] || {
        echo "Provider apiKey exec source is empty" >&2
        exit 1
      }
      "${command_parts[@]}"
      ;;
    *)
      echo "Unsupported apiKey format in provider config" >&2
      exit 1
      ;;
  esac
}

load_from_config() {
  [[ -n "$PROVIDER_NAME" ]] || return 0
  [[ -f "$CONFIG_PATH" ]] || {
    echo "OpenClaw config not found: $CONFIG_PATH" >&2
    exit 1
  }

  local provider_json
  provider_json=$(jq -ce --arg provider "$PROVIDER_NAME" '
    .models.providers[$provider] // .providers[$provider]
  ' "$CONFIG_PATH") || {
    echo "Provider not found in config: $PROVIDER_NAME" >&2
    exit 1
  }

  [[ -n "$BASE_URL" ]] || BASE_URL=$(echo "$provider_json" | jq -r '.baseUrl // empty')
  [[ -n "$API_KIND" ]] || API_KIND=$(echo "$provider_json" | jq -r '.api // empty')
  [[ -n "$MODEL_ID" ]] || MODEL_ID=$(echo "$provider_json" | jq -r '.models[0].id // empty')
  [[ -n "$API_KEY" ]] || API_KEY=$(resolve_api_key_from_provider "$provider_json")
}

load_from_config

[[ -n "$BASE_URL" && -n "$API_KEY" && -n "$API_KIND" && -n "$MODEL_ID" ]] || usage
BASE_URL="${BASE_URL%/}"

case "$API_KIND" in
  anthropic-messages)
    payload=$(jq -n \
      --arg model "$MODEL_ID" \
      '{
        model: $model,
        max_tokens: 32,
        messages: [
          { role: "user", content: "hello" }
        ]
      }')

    response=$(
      curl -sS -X POST "$BASE_URL/v1/messages" \
        -H "Content-Type: application/json" \
        -H "x-api-key: $API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "$payload"
    )

    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
      echo "$response" | jq --arg provider "$PROVIDER_NAME" '{
        ok: false,
        provider: ($provider // null),
        api: "anthropic-messages",
        errorType: .error.type,
        error: .error.message
      }'
      exit 1
    fi

    echo "$response" | jq --arg provider "$PROVIDER_NAME" '{
      ok: true,
      provider: ($provider // null),
      api: "anthropic-messages",
      id,
      model,
      text: ([.content[]? | select(.type == "text") | .text] | join(""))
    }'
    ;;

  openai-responses)
    payload=$(jq -n \
      --arg model "$MODEL_ID" \
      '{
        model: $model,
        input: "hello",
        max_output_tokens: 32
      }')

    response=$(
      curl -sS -X POST "$BASE_URL/responses" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_KEY" \
        -d "$payload"
    )

    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
      echo "$response" | jq --arg provider "$PROVIDER_NAME" '{
        ok: false,
        provider: ($provider // null),
        api: "openai-responses",
        errorType: .error.type,
        error: .error.message
      }'
      exit 1
    fi

    echo "$response" | jq --arg provider "$PROVIDER_NAME" '{
      ok: true,
      provider: ($provider // null),
      api: "openai-responses",
      id,
      model,
      text: (.output_text // ([.output[]?.content[]? | select(.type == "output_text") | .text] | join("")))
    }'
    ;;

  *)
    echo "Unsupported api: $API_KIND" >&2
    echo "Supported values: anthropic-messages, openai-responses" >&2
    exit 1
    ;;
esac
