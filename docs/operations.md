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
marzban backup

cp /var/lib/marzban/db.sqlite3 ~/marzban-backup-$(date +%Y%m%d).sqlite3
cp /var/lib/marzban/xray_config.json ~/xray-backup-$(date +%Y%m%d).json
cp /opt/heaven_ladder/config/generated-keys.env ~/keys-backup-$(date +%Y%m%d).env
```

## 添加新 Worker 节点

1. 新 VPS 运行 `deploy.sh node`
2. 主控面板 → Node Settings → Add Node
3. 为新节点配置独立 REALITY inbound
4. 客户端刷新订阅

## REALITY 密钥轮换

```bash
sudo bash scripts/configure-reality-inbound.sh
```

面板更新 inbound → Restart Core → 客户端更新订阅。

## 面板反代修复/重建

```bash
sudo bash scripts/setup-panel-proxy.sh
# 或
sudo bash deploy.sh panel-proxy
```

## Hysteria2 / Uptime Kuma

```bash
sudo bash deploy.sh extras
```

## IP 被封应急

1. `health-check.sh` 确认节点不可达
2. 更换 EIP，更新 `MASTER_IP`、Hosts、`setup-panel-proxy.sh`
3. 客户端刷新订阅

## 安全加固

| 措施 | 说明 |
|------|------|
| 面板/订阅 | 8080 + 强密码 + 订阅 Token |
| 代理 | 仅 443 对公网 |
| 本机 8000 | 不对公网开放 |
| SSH | 建议密钥登录 |

## 故障排查

详见 [troubleshooting.md](troubleshooting.md)。

### 快速命令

```bash
marzban status
marzban logs --tail 50
ss -tlnp | grep -E '443|8000|8080'
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8080/dashboard/
```
