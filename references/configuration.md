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
  - `scripts/balance.sh` and `scripts/refill.sh` read this value from `.env`
- `GACCODE_TOKEN`: cached auth token.
  - `scripts/balance.sh` and `scripts/refill.sh` will validate and reuse it when possible
  - On login refresh, the shared auth logic will write the latest token back into `.env`

## .env Example

Create `.env` in the skill root:

```dotenv
GACCODE_BASE_URL=https://gaccode.com
GACCODE_EMAIL=your_email@example.com
GACCODE_PASSWORD=your_password
GACCODE_TOKEN=
```

## Quick Check

Run:

```bash
scripts/balance.sh
scripts/refill.sh
```

If auth fails, verify email/password and confirm `.env` formatting is `KEY=value` with no extra quotes.
