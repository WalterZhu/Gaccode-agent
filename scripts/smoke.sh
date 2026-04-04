#!/usr/bin/env bash

set -euo pipefail

DEFAULT_CONFIG_PATH="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"

require_bin() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required binary: $1" >&2
    exit 1
  fi
}

require_arg_value() {
  local option="$1"
  local value="${2:-}"
  [[ -n "$value" ]] || {
    echo "Missing value for argument: $option" >&2
    exit 1
  }
}

PROVIDER_NAME=""
BASE_URL=""
API_KEY=""
API_KIND=""
MODEL_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)
      require_arg_value "$1" "${2:-}"
      PROVIDER_NAME="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

require_bin curl
require_bin jq

[[ -n "$PROVIDER_NAME" ]] || {
  echo "Missing required argument: --provider" >&2
  exit 1
}

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
  [[ -f "$DEFAULT_CONFIG_PATH" ]] || {
    echo "OpenClaw config not found: $DEFAULT_CONFIG_PATH" >&2
    exit 1
  }

  local provider_json
  provider_json=$(jq -ce --arg provider "$PROVIDER_NAME" '
    .models.providers[$provider] // .providers[$provider]
  ' "$DEFAULT_CONFIG_PATH") || {
    echo "Provider not found in config: $PROVIDER_NAME" >&2
    exit 1
  }

  BASE_URL=$(echo "$provider_json" | jq -r '.baseUrl // empty')
  API_KIND=$(echo "$provider_json" | jq -r '.api // empty')
  MODEL_ID=$(echo "$provider_json" | jq -r '.models[0].id // empty')
  API_KEY=$(resolve_api_key_from_provider "$provider_json")
}

load_from_config

[[ -n "$BASE_URL" ]] || {
  echo "Missing required value: base URL" >&2
  exit 1
}
[[ -n "$API_KEY" ]] || {
  echo "Missing required value: API key" >&2
  exit 1
}
[[ -n "$API_KIND" ]] || {
  echo "Missing required value: API kind" >&2
  exit 1
}
[[ -n "$MODEL_ID" ]] || {
  echo "Missing required value: model ID" >&2
  exit 1
}
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

    echo "$response" | jq --arg provider "$PROVIDER_NAME" --arg baseUrl "$BASE_URL" '{
      ok: true,
      provider: ($provider // null),
      baseUrl: ($baseUrl // null),
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

    echo "$response" | jq --arg provider "$PROVIDER_NAME" --arg baseUrl "$BASE_URL" '{
      ok: true,
      provider: ($provider // null),
      baseUrl: ($baseUrl // null),
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
