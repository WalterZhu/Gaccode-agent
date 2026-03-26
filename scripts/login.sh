#!/usr/bin/env bash
# 登录 gaccode.com，获取 token 并缓存到 .gaccode_oauth_token.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TOKEN_FILE="$ROOT_DIR/.gaccode_oauth_token.json"
TOOLS_FILE="$ROOT_DIR/TOOLS.md"

# 从 TOOLS.md 读取配置
gaccode_email=$(grep -oP '(?<=gaccode_email: ).*' "$TOOLS_FILE" | tr -d '[:space:]')
gaccode_password=$(grep -oP '(?<=gaccode_password: ).*' "$TOOLS_FILE" | tr -d '[:space:]')
gaccode_base_url=$(grep -oP '(?<=gaccode_base_url: ).*' "$TOOLS_FILE" | tr -d '[:space:]')
gaccode_base_url="${gaccode_base_url:-https://gaccode.com}"

response=$(curl -sf -X POST "$gaccode_base_url/api/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$gaccode_email\",\"password\":\"$gaccode_password\"}")

token=$(echo "$response" | grep -oP '(?<="token":")[^"]+')

if [[ -z "$token" ]]; then
  echo "登录失败" >&2
  exit 1
fi

expires_at=$(date -u -d "+24 hours" "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
  || date -u -v+24H "+%Y-%m-%dT%H:%M:%SZ")

cat > "$TOKEN_FILE" <<EOF
{
  "token": "$token",
  "expires_at": "$expires_at"
}
EOF

echo "登录成功，token 已缓存至 $TOKEN_FILE"
