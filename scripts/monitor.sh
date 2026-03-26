#!/usr/bin/env bash
# gaccode 积分监控脚本 - 用于 cron 任务

set -euo pipefail

SKILL_DIR="$HOME/.openclaw/workspace-admin/skills/gaccode"
cd "$SKILL_DIR"

# 查询余额
balance_json=$(bash scripts/balance.sh)
balance=$(echo "$balance_json" | jq -r '.balance')
credit_cap=$(echo "$balance_json" | jq -r '.creditCap')

# 计算 10% 的上限
threshold=$(echo "$credit_cap * 0.1" | bc)

# 如果低于 80%，报告
if (( $(echo "$balance < $threshold" | bc) )); then
  percentage=$(echo "scale=1; $balance * 100 / $credit_cap" | bc)
  echo "⚠️ gaccode 积分过低：$balance / $credit_cap ($percentage%)"
  echo "余额详情："
  echo "$balance_json" | jq .
else
  percentage=$(echo "scale=1; $balance * 100 / $credit_cap" | bc)
  echo "✅ gaccode 积分正常：$balance / $credit_cap ($percentage%)"
fi
