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

## Available scripts

- `scripts/gaccode.sh balance` — Return the current credit balance, cap, refill rate, and most recent refill time.
- `scripts/gaccode.sh refill` — Trigger the scripted gaccode refill flow.
