#!/usr/bin/env bash
# /gaccode 命令处理脚本

set -euo pipefail

SKILL_DIR="$HOME/.openclaw/workspace-admin/skills/gaccode"
cd "$SKILL_DIR"

# 查询余额
balance_json=$(bash scripts/balance.sh)
balance=$(echo "$balance_json" | jq -r '.balance')
credit_cap=$(echo "$balance_json" | jq -r '.creditCap')
refill_rate=$(echo "$balance_json" | jq -r '.refillRate')
last_refill=$(echo "$balance_json" | jq -r '.lastRefill')

# 计算百分比
percentage=$(echo "scale=1; $balance * 100 / $credit_cap" | bc)

# 格式化输出
cat <<EOF
💳 **Gaccode 积分状态**

余额: **$balance** / $credit_cap ($percentage%)
每日充值: $refill_rate 积分
最后充值: $last_refill

$(if (( $(echo "$balance < $credit_cap * 0.1" | bc) )); then
  echo "⚠️ 积分过低，建议充值"
else
  echo "✅ 积分充足"
fi)
EOF
