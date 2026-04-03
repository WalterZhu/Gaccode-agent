---
name: gaccode
description: "Use gaccode scripts to inspect balance, trigger refill when needed, choose a relay node, and smoke-test Claude Code or OpenAI Codex provider configs."
metadata:
  {
    "openclaw":
      {
        "emoji": "💳",
        "requires": { "bins": ["curl", "jq", "bc", "fping"] },
        "install":
          [
            {
              "id": "fping-brew",
              "kind": "brew",
              "formula": "fping",
              "bins": ["fping"],
              "label": "Install fping (brew)",
            },
            {
              "id": "jq-brew",
              "kind": "brew",
              "formula": "jq",
              "bins": ["jq"],
              "label": "Install jq (brew)",
            },
            {
              "id": "bc-brew",
              "kind": "brew",
              "formula": "bc",
              "bins": ["bc"],
              "label": "Install bc (brew)",
            },
          ],
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

## Commands

- `/gaccode refill` -> `scripts/refill.sh`
- `/gaccode refill --force` -> `scripts/refill.sh --force`
- `/gaccode relay` -> `scripts/relay.sh`
- `/gaccode probe --provider custom-claude-code` -> `scripts/probe.sh --provider custom-claude-code`
- `/gaccode probe --provider custom-openai-codex` -> `scripts/probe.sh --provider custom-openai-codex`

## Refill

Use `scripts/refill.sh` to check balance and trigger the refill flow when needed.

```bash
scripts/refill.sh
scripts/refill.sh --force
```

## Relay

Use `scripts/relay.sh` to choose the lowest-latency relay node with `fping`.

```bash
scripts/relay.sh
```

## Probe

Use `scripts/probe.sh` to send a minimal text-only `hello` request. By default, it reads the provider from `~/.openclaw/openclaw.json`.

Claude Code:

```bash
scripts/probe.sh --provider custom-claude-code
```

OpenAI Codex:

```bash
scripts/probe.sh --provider custom-openai-codex
```

## References

- [references/configuration.md](references/configuration.md)
- [references/openclaw_custom_providers.md](references/openclaw_custom_providers.md)
