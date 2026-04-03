---
name: gaccode
description: "Use gaccode scripts to inspect balance, trigger refill when needed, choose a relay node, and smoke-test Claude Code or OpenAI Codex provider configs."
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

Use this skill when you need to:

- Check gaccode credit balance
- Trigger the refill flow
- Select the best relay node
- Smoke-test a Claude Code or OpenAI Codex provider config

Before using this skill, ensure gaccode credentials are configured correctly.

## Main Scripts

Balance check and refill:

- `scripts/gaccode.sh`
- `scripts/gaccode.sh force`

Relay node selection:

- `scripts/select_node.sh`
- `scripts/select_node.sh --json`

Provider smoke test:

- `scripts/test_provider.sh`

## Provider Smoke Test

Use `scripts/test_provider.sh` to send a minimal text-only `hello` request. By default, it reads the provider from `~/.openclaw/openclaw.json`.

Claude Code:

```bash
scripts/test_provider.sh --provider custom-claude-code
```

OpenAI Codex:

```bash
scripts/test_provider.sh --provider custom-openai-codex
```

## Example Output

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

## References

- [references/configuration.md](references/configuration.md)
- [references/openclaw_custom_providers.md](references/openclaw_custom_providers.md)
