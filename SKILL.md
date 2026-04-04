---
name: gaccode
description: "Use gaccode scripts to inspect balance, trigger refill when needed, and smoke-test Claude Code or OpenAI Codex provider configs."
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
- Smoke-test a Claude Code or OpenAI Codex provider config

Before using this skill, ensure gaccode credentials are configured correctly.

## Commands

- `/gaccode refill` -> `scripts/refill.sh`
- `/gaccode refill --force` -> `scripts/refill.sh --force`
- `/gaccode probe --provider <provider-key>` -> `scripts/probe.sh --provider <provider-key>`

## Refill

Use `scripts/refill.sh` to check balance and trigger the refill flow when needed.

```bash
scripts/refill.sh
scripts/refill.sh --force
```

## Probe

Use `scripts/probe.sh` to send a minimal text-only `hello` request. `--provider` is the provider key in `~/.openclaw/openclaw.json`. The script reads that provider config and automatically chooses the correct validation flow from its `api` value. If the configured `baseUrl` uses a gaccode relay hostname, the script benchmarks the known relay nodes with `fping` and probes the lowest-latency node while preserving the original path.

```bash
scripts/probe.sh --provider claude-code
```

## References

- [references/configuration.md](references/configuration.md)
- [references/openclaw_custom_providers.md](references/openclaw_custom_providers.md)
