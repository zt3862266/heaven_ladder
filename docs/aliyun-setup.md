# 阿里云安全组配置指南

## 主控 VPS 安全组

| 规则方向 | 协议 | 端口 | 授权对象 | 说明 |
|---------|------|------|---------|------|
| 入方向 | TCP | 22 | 你的 IP/32 | SSH 管理 |
| 入方向 | TCP | 443 | 0.0.0.0/0 | VLESS REALITY（代理） |
| 入方向 | TCP | 8080 | 0.0.0.0/0 | Marzban 面板 + 订阅（Nginx 反代） |
| 入方向 | TCP | 3001 | 你的 IP/32 | Uptime Kuma（可选） |
| 入方向 | UDP | 8443 | 0.0.0.0/0 | Hysteria2 备用（可选） |

**说明**：

- **不要**对公网开放 **8000**：Marzban 无 SSL 时只监听 `127.0.0.1:8000`。
- 面板与手机/电脑拉订阅使用 **8080**（`setup-panel-proxy.sh` 默认端口，可在 `.env` 改 `PANEL_PROXY_PORT`）。

若仅通过 SSH 隧道管理面板、且手机用同一订阅链接，仍需 **8080** 对手机网络可达，或使用域名 HTTPS。

## Worker VPS 安全组

| 规则方向 | 协议 | 端口 | 授权对象 | 说明 |
|---------|------|------|---------|------|
| 入方向 | TCP | 22 | 你的 IP/32 | SSH 管理 |
| 入方向 | TCP | 443 | 0.0.0.0/0 | VLESS REALITY |
| 入方向 | TCP | 62050 | 主控 IP/32 | Marzban Node 通信 |
| 入方向 | UDP | 8443 | 0.0.0.0/0 | Hysteria2 备用（可选） |

**Worker 不要开放 8000/8080 面板端口。**

## 阿里云控制台操作步骤

1. 登录 [阿里云 ECS 控制台](https://ecs.console.aliyun.com/)
2. 选择目标实例 → **安全组** → **配置规则**
3. **入方向** → **手动添加**，按上表填写

## 带宽建议

| 用途 | 建议带宽 |
|------|---------|
| 日常浏览 | ≥ 5 Mbps |
| 视频/会议 | ≥ 10 Mbps |
| 大文件下载 | 按量计费或 ≥ 20 Mbps |

## IP 被封时的处理

1. ECS 控制台 → 解绑旧 EIP → 绑定新 EIP
2. Marzban **Hosts** 与 `.env` 的 `MASTER_IP` 改为新 IP
3. 重新运行 `sudo bash scripts/setup-panel-proxy.sh`
4. 客户端刷新订阅

## 家庭网络 IP（白名单可选）

- IPv4： https://api.ipify.org
- IPv6： https://api6.ipify.org

仅 IPv6 家宽时，`ADMIN_WHITELIST_IP` 的 IPv4 白名单往往无效，请使用 **8080 公网反代 + 订阅 Token**，见 [troubleshooting.md](troubleshooting.md)。

## 相关文档

- [panel-and-subscription.md](panel-and-subscription.md)
- [troubleshooting.md](troubleshooting.md)
