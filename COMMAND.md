---
name: gaccode
description: "查询 gaccode 积分余额状态"
metadata:
  openclaw:
    emoji: "💳"
    commands:
      - name: gaccode
        description: "查询 gaccode 积分余额"
        help: "显示当前 gaccode 积分余额、百分比和充值状态"
---

# /gaccode 命令

查询 gaccode 积分余额状态。

## 使用

```
/gaccode
```

## 输出

显示：
- 当前余额 / 上限
- 百分比
- 每日充值速率
- 最后充值时间
- 状态提示（充足/过低）
