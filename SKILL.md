---
name: gaccode-assistant
description: "查询 gaccode.com API 获取积分余额和使用情况，支持轮询监控积分并在积分过低时自动充值。当被问到 gaccode 积分、余额、用量、API 配额状态、账户余额查询、积分监控或自动充值时使用。"
metadata:
  {
    "openclaw":
      {
        "emoji": "💳",
        "requires": { "bins": ["curl", "bc"] },
        "install":
          [
            {
              "id": "brew-curl",
              "kind": "brew",
              "formula": "curl",
              "bins": ["curl"],
              "label": "Install curl (brew)",
            },
            {
              "id": "brew-bc",
              "kind": "brew",
              "formula": "bc",
              "bins": ["bc"],
              "label": "Install bc (brew)",
            },
          ],
      },
  }
---

# Gaccode Assistant

查询 gaccode.com API 获取积分余额和使用情况，支持轮询监控积分并在积分过低时自动充值。

## When to Use

✅ **USE this skill when:**

- "查询 gaccode 积分余额"
- "gaccode 还有多少积分？"
- "监控积分，低于 100 时自动充值"
- "帮我充值 gaccode 积分"
- API 配额状态查询

## When NOT to Use

❌ **DON'T use this skill when:**

- 查询其他平台的积分或余额
- 需要历史用量统计分析

## 配置要求

使用本 skill 前需在 `TOOLS.md` 中填入以下配置：

| 配置项 | 说明 |
|--------|------|
| `gaccode_email` | gaccode.com 登录邮箱 |
| `gaccode_password` | gaccode.com 登录密码 |
| `gaccode_base_url` | API 基础地址，默认 `https://gaccode.com` |

> `.gaccode_oauth_token.json` 由 skill 自动管理，无需配置。

`.gaccode_oauth_token.json` 文件格式：
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_at": "2026-03-27T12:00:00Z"
}
```

## Authentication

Token 缓存策略：
1. 先读取 `.gaccode_oauth_token.json`，若存在且 `expires_at` 未过期则直接使用
2. 若文件不存在、token 已过期或请求返回 401，则重新登录获取新 token
3. 登录成功后将新 token 和过期时间写入 `.gaccode_oauth_token.json`

## Quick Start

```bash
# 查询余额
{baseDir}/scripts/balance.sh

# 手动触发充值
{baseDir}/scripts/refill.sh
```

## Scripts

| 脚本 | 说明 |
|------|------|
| `login.sh` | 登录并缓存 token |
| `balance.sh` | 查询当前积分余额 |
| `refill.sh` | 触发积分充值 |

## 积分监控

积分监控通过 openclaw heartbeat 实现，配置见 `HEARTBEAT.md`。每次心跳自动检查余额，低于阈值时自动充值，无需手动运行脚本。

## API

- 登录：`POST /api/login`，body `{"email":"...","password":"..."}`，返回 `token`
- 余额：`GET /api/credits/balance`，header `Authorization: Bearer <token>`，返回 `balance / creditCap / refillRate / lastRefill`
- 充值：`POST /api/ticket`，header `Authorization: Bearer <token>`，触发积分充值
