---
name: gaccode
description: "Check gaccode.com credit balance and trigger the refill flow when needed. Use when you need to inspect remaining gaccode credits, verify the credit cap or recent refill timing, or manually request more credits."
metadata:
  {
    "openclaw":
      {
        "emoji": "💳",
        "requires": { "bins": ["curl", "jq", "bc"] },
      },
  }
---

# Gaccode

Before using this skill, ensure gaccode credentials are configured correctly.

Authentication, token refresh, and API details are encapsulated by the script. Prefer script subcommands instead of reimplementing the login flow at the agent layer.

Command: `scripts/gaccode.sh balance`

Example output:

```json
{
  "balance": 120,
  "creditCap": 1000,
  "refillRate": 50,
  "lastRefill": "2026-03-27T09:00:00.000Z",
  "balanceRatio": 0.12
}
```

Command: `scripts/gaccode.sh refill`

Example outputs:

```text
无需执行：当前余额 120 / 1000 (12.00%)，执行界限 < 5.00%
```

```text
重置成功：您的积分已重置。
```

```text
重置失败：请登录gaccode网站查看
```
