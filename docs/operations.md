# 运维手册

## 每月检查清单（约 15 分钟）

- [ ] 更新 Marzban：`sudo bash scripts/update-all.sh`
- [ ] 更新各 Worker 节点：`sudo bash scripts/update-all.sh --node`
- [ ] 运行健康检查：`bash scripts/health-check.sh`
- [ ] 查看 Marzban 面板流量是否异常
- [ ] 确认订阅 Token 未泄露
- [ ] 备份 Marzban 数据库：`/var/lib/marzban/db.sqlite3`

## 备份

```bash
# 主控 VPS 上执行
marzban backup

# 或手动备份
cp /var/lib/marzban/db.sqlite3 ~/marzban-backup-$(date +%Y%m%d).sqlite3
cp /var/lib/marzban/xray_config.json ~/xray-backup-$(date +%Y%m%d).json
cp /opt/heaven_ladder/config/generated-keys.env ~/keys-backup-$(date +%Y%m%d).env
```

## 添加新 Worker 节点

1. 新 VPS 运行 `system-baseline.sh --skip-panel-port`
2. 新 VPS 运行 `install-marzban-node.sh`
3. 主控面板 → Node Settings → Add Node → 粘贴证书
4. 为新节点配置独立 REALITY inbound（不同 privateKey / shortId）
5. 客户端刷新订阅即可

## REALITY 密钥轮换

```bash
# 在主控 VPS
sudo bash scripts/configure-reality-inbound.sh
# 按提示在面板中更新 inbound 并重启 Core
# 客户端刷新订阅
```

## Hysteria2 备用协议

在 1~2 台节点部署：

```bash
sudo bash scripts/setup-hysteria2.sh
```

客户端会在订阅更新后自动获取 Hysteria2 节点（需在 Marzban 中配置对应 inbound）。

## Uptime Kuma 监控

```bash
sudo bash scripts/setup-uptime-kuma.sh
```

建议监控项：

| 名称 | 类型 | 目标 | 间隔 |
|------|------|------|------|
| SG REALITY | Port | sg-ip:443/tcp | 60s |
| JP REALITY | Port | jp-ip:443/tcp | 60s |
| US REALITY | Port | us-ip:443/tcp | 60s |
| US Hysteria2 | Port | us-ip:8443/udp | 60s |

通知渠道：Telegram Bot（在 `.env` 中配置 `TELEGRAM_BOT_TOKEN` 和 `TELEGRAM_CHAT_ID`）。

## IP 被封应急流程

```
1. 确认被封: health-check.sh 全部 FAIL
2. 阿里云控制台 → 更换 EIP
3. Marzban 面板 → 更新 Node Address
4. 客户端 → 刷新订阅
5. 如仍不可用 → 运行 configure-reality-inbound.sh 轮换 REALITY 密钥
```

## 安全加固

| 措施 | 状态 |
|------|------|
| 面板端口 IP 白名单 | system-baseline.sh 自动配置 |
| 订阅 Token 鉴权 | Marzban Settings → Subscription |
| SSH 密钥登录（禁用密码） | 建议手动配置 |
| 定期更新 | update-all.sh |
| 不公开分享订阅链接 | 人工遵守 |

## 故障排查

### Marzban 面板无法访问

```bash
marzban status
marzban logs
# 检查 UFW: ufw status
# 检查阿里云安全组 8000 端口
```

### 节点 Connected 但客户端连不上

```bash
# 检查 XRay 是否监听 443
ss -tlnp | grep 443
# 检查 REALITY 配置
docker exec $(docker ps --format '{{.Names}}' | grep marzban | head -1) xray version
# 查看 XRay 日志
marzban logs --follow
```

### Worker 节点无法连接主控

```bash
# Worker 上检查
cat /var/lib/marzban-node/ssl_client_cert.pem  # 证书是否存在
cd ~/Marzban-node && docker compose logs
# 确认主控安全组允许 Worker IP 访问 62050
```
