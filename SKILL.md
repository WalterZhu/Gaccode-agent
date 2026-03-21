---
name: gaccode
description: Query gaccode.com API for credit balance and usage information. Use when asked about gaccode credits, balance, usage, API quota status, or gaccode account balance checks.
---

# gaccode

Query the gaccode.com API to check credit balance and usage.

## Authentication

Use the gaccode account email and password stored in `TOOLS.md`.
Do not rely on a long-lived JWT token unless the user explicitly provides one for temporary debugging.
Preferred flow: log in, get a fresh JWT, then call the balance endpoint.

## Preferred workflow

Use the bundled script:

```bash
./scripts/get_balance.sh <email> <password>
```

The script:
1. Logs in via `POST /api/login`
2. Extracts the returned JWT token
3. Calls `GET /api/credits/balance`
4. Prints JSON response

## Raw API flow

### Login

```bash
curl -s https://gaccode.com/api/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"you@example.com","password":"your-password"}'
```

Example response:

```json
{
  "message": "Login successful.",
  "token": "<JWT>",
  "user": {
    "id": 38330,
    "email": "hqzhu0461@163.com"
  }
}
```

### Check credit balance

```bash
curl -s https://gaccode.com/api/credits/balance \
  -H "Authorization: Bearer <JWT_TOKEN>"
```

Example response:

```json
{
  "balance": 853,
  "creditCap": 12000,
  "refillRate": 300,
  "lastRefill": "2026-03-21T12:33:04.900Z"
}
```

## Response fields

- `balance`: current available credits
- `creditCap`: maximum credit limit
- `refillRate`: credits added per refill cycle
- `lastRefill`: timestamp of last refill (UTC)

## Notes

- JWT token expires periodically; re-login instead of assuming an old token still works.
- If the balance endpoint returns 401, run the login flow again.
- Prefer the bundled Node script for repeatable checks.
cks.
