# OpenClaw Custom Providers Guide

This guide explains how to configure custom providers in `~/.openclaw/openclaw.json` for two target integrations:

- Claude Code
- OpenAI Codex

The examples below are OpenClaw provider entries and follow the provider structure expected by these clients.

## Provider Structure

Each provider entry typically includes:

- `baseUrl`: upstream API endpoint
- `apiKey`: provider credential
- `api`: request format used by the client
- `models`: models exposed by this provider

Common model fields:

- `id`: upstream model ID
- `name`: display name in the client
- `contextWindow`: maximum context length exposed to the client
- `reasoning`: whether the model should be marked as a reasoning model
- `input`: supported input types, usually `text` and optionally `image`

## Claude Code

Use this provider when the client expects Anthropic-style Messages API semantics.

### Example

```json
{
  "providers": {
    "claude-code": {
      "baseUrl": "https://relay03.gaccode.com/claudecode",
      "apiKey": "YOUR_API_KEY",
      "api": "anthropic-messages",
      "models": [
        {
          "id": "claude-sonnet-4-6",
          "name": "claude-sonnet-4-6",
          "contextWindow": 1000000,
          "reasoning": false,
          "input": ["text", "image"]
        }
      ]
    }
  }
}
```

## OpenAI Codex

Use this provider when the client expects OpenAI Responses API semantics.

### Example

```json
{
  "providers": {
    "openai-codex": {
      "baseUrl": "https://relay03.gaccode.com/codex/v1",
      "apiKey": "YOUR_API_KEY",
      "api": "openai-responses",
      "models": [
        {
          "id": "gpt-5.4",
          "name": "GPT-5.4",
          "api": "openai-responses",
          "contextWindow": 1050000,
          "reasoning": false,
          "input": ["text", "image"]
        }
      ]
    }
  }
}
```

## Choosing the Relay Node

Gaccode exposes multiple relay nodes:

- `gaccode.com`
- `api.gaccode.com`
- `relay01.gaccode.com`
- `relay03.gaccode.com`
- `relay05.gaccode.com`
- `relay07.gaccode.com`
- `relay08.gaccode.com`

Use `scripts/nodes.sh` to benchmark these nodes with `fping`.

```bash
scripts/nodes.sh
```

If you want to pin a relay manually, replace the hostname in `baseUrl`, for example:

```text
https://relay05.gaccode.com/claudecode
https://relay05.gaccode.com/codex/v1
```

## Field Guidance

### `baseUrl`

- Claude Code: use the Claude relay path such as `https://relay03.gaccode.com/claudecode`
- OpenAI Codex: use the Codex relay path such as `https://relay03.gaccode.com/codex/v1`

### `apiKey`

- Use the credential issued for the relay
- Do not hardcode production secrets in shared config files or docs

### `api`

- Claude Code: `anthropic-messages`
- OpenAI Codex: `openai-responses`

### `models`

Use a `models` array and declare each exposed model explicitly. One entry is enough if you only want to expose a single model.

Recommended per-model fields:

- `id`
- `name`
- `contextWindow`
- `reasoning`
- `input`

## Supported Model IDs and Context

| Model ID | Recommended `contextWindow` |
|---|---:|
| `claude-opus-4-6` | `1000000` |
| `claude-sonnet-4-6` | `1000000` |
| `claude-haiku-4-5-20251001` | `200000` |
| `gpt-5.4` | `1050000` |
| `gpt-5.3-codex` | `400000` |

If your relay operator documents a different limit for the same ID, follow the relay-specific limit instead of the upstream default.

## Validation Checklist

1. Confirm `baseUrl` matches the correct product path.
2. Confirm `api` matches the client protocol.
3. Confirm every `models[].id` is supported by the upstream relay.
4. Confirm `apiKey` is valid.
5. Test one text-only `hello` request.

## Smoke Test

Use `scripts/smoke.sh` to send the simplest possible text-only request. `--provider` is the provider key in `~/.openclaw/openclaw.json`.

```bash
scripts/smoke.sh --provider claude-code
```

The smoke script reads `baseUrl`, `apiKey`, `api`, and `model` from the selected provider config, then automatically chooses the correct validation flow from the provider's `api` value.

On success, the script prints JSON with `ok: true` and the returned text. On failure, it prints `ok: false` with the upstream error.

## Troubleshooting

| Error | Likely Cause | Fix |
|---|---|---|
| 401 / authentication failed | Invalid or expired key | Verify `apiKey` |
| Model not found | Wrong `models[].id` | Use a supported model ID |
| Unsupported API format | Wrong `api` value | Use `anthropic-messages` or `openai-responses` as appropriate |
| Request hits wrong backend | Wrong `baseUrl` path | Check `/claudecode` vs `/codex/v1` |
| Image input fails | Model or backend does not support images | Remove `"image"` from `input` or switch models |

## Best Practices

1. Separate Claude Code and OpenAI Codex into different provider entries.
2. Keep model names user-friendly, but keep `id` aligned with the upstream model ID.
3. Start with one verified relay node, then optimize latency later.
4. Add only the models you actually want users to select, and prefer a single entry when no switching is needed.
