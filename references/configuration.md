# Configuration

The `gaccode` skill reads configuration only from `.env` in the skill root.
Shell environment variables are ignored by script logic.

## Authentication Strategy

At the moment, gaccode does not provide an API key flow for this use case.
So this skill uses credential-based login to obtain and refresh a token for API calls.

When gaccode officially supports API keys for the same workflow, this skill will be updated to prefer API-key authentication.

## Required Variables

- `GACCODE_EMAIL`: Your gaccode account email.
- `GACCODE_PASSWORD`: Your gaccode account password.

## Optional Variables

- `GACCODE_BASE_URL`: gaccode base URL.
  - Default: `https://gaccode.com`
  - **Node Selection**: Gaccode operates multiple relay nodes. Choose the optimal node based on latency:
    - Available nodes: `gaccode.com`, `api.gaccode.com`, `relay01.gaccode.com`, `relay03.gaccode.com`, `relay05.gaccode.com`, `relay07.gaccode.com`, `relay08.gaccode.com`
    - Run `scripts/select_node.sh` to automatically select the best node
    - Example: `GACCODE_BASE_URL=https://relay05.gaccode.com`

## .env Example

Create `.env` in the skill root (`/Users/hqzhu/dev/agent/skills/gaccode/.env`):

```dotenv
GACCODE_BASE_URL=https://gaccode.com
GACCODE_EMAIL=your_email@example.com
GACCODE_PASSWORD=your_password
```

## Quick Check

Run:

```bash
scripts/gaccode.sh
```

If auth fails, verify email/password and confirm `.env` formatting is `KEY=value` with no extra quotes.
