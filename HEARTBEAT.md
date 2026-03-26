# Gaccode 积分监控

每次心跳执行以下检查：

- [ ] 运行 `{baseDir}/scripts/balance.sh` 查询当前积分余额
- [ ] 若 `balance` 低于 100，运行 `{baseDir}/scripts/refill.sh` 触发充值，并报告充值结果
- [ ] 若 `balance` 正常，无需任何操作

如果积分正常且无需充值，回复 HEARTBEAT_OK
