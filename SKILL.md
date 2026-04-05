---
name: gaccode
description: "Use gaccode scripts to inspect balance, trigger refill when needed, benchmark gaccode nodes, and smoke-test provider configs."
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
- Benchmark gaccode relay nodes
- Smoke-test a Claude Code or OpenAI Codex provider config

Before using this skill, ensure gaccode credentials are configured correctly.

## Execution

Before running any bundled shell script, change to the skill root directory that contains this `SKILL.md`.

## Response Format

When handling `/gaccode` commands:

- Default to a short, formal plain-text result instead of raw JSON.
- Summarize the script result directly without adding extra explanation or interpretation.
- Preserve key values exactly when reporting balances, latency values, URLs, model IDs, or provider IDs.
- Only include raw script output when it is necessary for debugging or the user explicitly asks for it.

## Refill

Command: `/gaccode refill` -> `./scripts/refill.sh`

Use `./scripts/refill.sh` to trigger the refill flow.

## Balance

Command: `/gaccode` -> `./scripts/balance.sh`

Use `./scripts/balance.sh` to query the current credit balance without triggering refill.

## Node

Command: `/gaccode node` -> `./scripts/nodes.sh`

Use `./scripts/nodes.sh` to benchmark gaccode relay nodes with `fping`.

## Smoke

Command: `/gaccode smoke <provider-key>` -> `./scripts/smoke.sh --provider <provider-key>`

Use `./scripts/smoke.sh` to send a minimal text-only `hello` request. `--provider` is the provider key in `~/.openclaw/openclaw.json`. The script reads that provider config and automatically chooses the correct validation flow from its `api` value.

## References

- [references/configuration.md](references/configuration.md)
- [references/openclaw_custom_providers.md](references/openclaw_custom_providers.md)
