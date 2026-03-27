---
name: gaccode
description: "查询 gaccode.com 积分余额，支持低积分自动充值。"
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

## 配置要求

使用本 skill 前需在 `TOOLS.md` 中填入以下配置：

| 配置项 | 说明 |
|--------|------|
| `gaccode_email` | gaccode.com 登录邮箱 |
| `gaccode_password` | gaccode.com 登录密码 |
| `gaccode_base_url` | API 基础地址，默认 `https://gaccode.com` |

> `.gaccode_oauth_token` 由 skill 自动管理，无需配置。文件内容为纯文本 token 字符串。

## Authentication

Token 缓存策略：
1. 先检查 `.gaccode_oauth_token` 是否存在，并请求 `/api/me` 验证有效性
2. 验证失败则重新登录，将新 token 写入 `.gaccode_oauth_token`

## Quick Start

```bash
# 查询余额
{baseDir}/scripts/gaccode.sh balance

# 手动触发充值
{baseDir}/scripts/gaccode.sh refill
```

## Scripts

| 脚本 | 说明 |
|------|------|
| `gaccode.sh balance` | 查询当前积分余额 |
| `gaccode.sh refill` | 触发积分充值 |
