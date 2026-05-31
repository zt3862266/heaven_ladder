# 面板与订阅访问

## 端口分工

| 端口 | 用途 | 监听方 | 安全组建议 |
|------|------|--------|------------|
| **443** | VLESS REALITY（翻墙） | Xray | `0.0.0.0/0` |
| **8000** | Marzban 面板（仅本机） | Uvicorn `127.0.0.1` | 不应对公网开放 |
| **8080** | 面板 + 订阅（公网） | Nginx → `127.0.0.1:8000` | `0.0.0.0/0`（靠 Token + 强密码） |

**8080 能打开 ≠ 代理一定能用**；代理是否正常看 **443** 与客户端节点配置。

## 为什么不能用 `UVICORN_HOST=0.0.0.0`

Marzban 在未配置 `UVICORN_SSL_CERTFILE` / `UVICORN_SSL_KEYFILE` 时，**会忽略** `.env` 中的 `UVICORN_HOST`，强制绑定 `127.0.0.1`（官方安全设计）。

公网访问请使用：

```bash
sudo bash scripts/setup-panel-proxy.sh
```

详见 [Marzban 文档](https://gozargah.github.io/marzban/en/docs/configuration)。

## 一键配置反代（无域名）

```bash
cd /opt/heaven_ladder
# .env 中设置 MASTER_IP=你的公网IP，可选 PANEL_PROXY_PORT=8080
sudo bash scripts/setup-panel-proxy.sh
```

脚本将：

1. 安装 Nginx，监听 `PANEL_PROXY_PORT`（默认 8080）
2. 反代到 `127.0.0.1:8000`
3. UFW 放行该端口
4. 写入 `/opt/marzban/.env` 的 `XRAY_SUBSCRIPTION_URL_PREFIX`

## 订阅 URL 格式

假设公网 IP 为 `8.209.239.243`，Token 为 `YOUR_TOKEN`：

| 用途 | URL |
|------|-----|
| Clash Verge Rev | `http://8.209.239.243:8080/sub/YOUR_TOKEN/clash-meta` |
| Shadowrocket / v2rayNG | `http://8.209.239.243:8080/sub/YOUR_TOKEN` |
| 面板 | `http://8.209.239.243:8080/dashboard/` |

## Hosts 设置（Settings → Hosts）

为 **VLESS TCP REALITY** 保留 **一条** Host：

| 字段 | 值 |
|------|-----|
| Remark | 可保留模板或自定义 |
| Address | **公网 IP**（推荐写死，如 `8.209.239.243`） |
| 高级 → Port | `443` |
| 高级 → SNI | `www.microsoft.com`（与 Core `serverNames` 一致） |

删除空白 Host 行；不用 Shadowsocks 则清理 **Shadowsocks TCP** 下的 Host。

变量说明见 [Host Settings | Marzban](https://gozargah.github.io/marzban/en/docs/host-settings)。

## 用户 Flow

**Users** → 用户 → **Vless** 行右侧 **⋮** → Flow：**xtls-rprx-vision** → 修改。

## SSH 隧道（可选）

仅管理面板、不暴露 8080 时：

```bash
ssh -N -L 8000:127.0.0.1:8000 root@<VPS_IP>
```

浏览器访问 `http://127.0.0.1:8000/dashboard/`。  
手机拉订阅仍需公网 8080 或域名 HTTPS。

## 部署后检查清单

- [ ] `sudo bash scripts/setup-panel-proxy.sh`
- [ ] 阿里云放行 **443**、**8080**
- [ ] Core 仅 VLESS REALITY inbound
- [ ] Hosts：单条，Address = 公网 IP
- [ ] 用户：Vless + Flow `xtls-rprx-vision`
- [ ] `sudo marzban cli admin create --sudo`
- [ ] 客户端用 `/clash-meta` 订阅，全局 + 选 VLESS + TUN

故障排查：[troubleshooting.md](troubleshooting.md)
