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

Command: `scripts/gaccode.sh`
Optional force mode: `scripts/gaccode.sh force`

See `references/configuration.md` for setup and configuration examples.

Example outputs:

```json
{
  "balance": 120,
  "creditCap": 1000,
  "refillRate": 50,
  "lastRefill": "2026-03-27T09:00:00.000Z",
  "balanceRatio": 0.12,
  "action": "skip_refill",
  "reason": "balance_ratio_not_below_threshold",
  "refillThreshold": 0.05,
  "forced": false
}
```

```json
{
  "action": "refill",
  "status": "success",
  "refillThreshold": 0.05,
  "forced": false,
  "message": "您的积分已重置。",
  "balanceBefore": {
    "balance": 20,
    "creditCap": 1000,
    "refillRate": 50,
    "lastRefill": "2026-03-26T09:00:00.000Z",
    "balanceRatio": 0.02
  },
  "balanceAfter": {
    "balance": 1000,
    "creditCap": 1000,
    "refillRate": 50,
    "lastRefill": "2026-03-27T09:00:00.000Z",
    "balanceRatio": 1
  }
}
```

```json
{
  "action": "refill",
  "status": "failed",
  "refillThreshold": 0.05,
  "forced": true,
  "message": "请登录gaccode网站查看",
  "balanceBefore": {
    "balance": 20,
    "creditCap": 1000,
    "refillRate": 50,
    "lastRefill": "2026-03-26T09:00:00.000Z",
    "balanceRatio": 0.02
  }
}
```
