# 故障排查与常见坑

本文档汇总部署与客户端使用中的常见问题。面板与订阅说明见 [panel-and-subscription.md](panel-and-subscription.md)。

## 部署阶段

### `export: '#': not a valid identifier`（load_env）

**原因**：`.env` 行内中文注释被旧版 `load_env` 当成变量名。

**处理**：使用本仓库最新 `scripts/common.sh`（已支持去掉行内注释），或删除 `.env` 行内注释。

### 公网访问 `:8000` 超时或 502

**原因**：

1. Marzban **无 SSL 时强制监听 `127.0.0.1:8000`**，改 `UVICORN_HOST=0.0.0.0` 无效。
2. 与 Nginx 同占 8000 会导致 `bind() failed (98: Address already in use)`。

**处理**：

```bash
sudo bash scripts/setup-panel-proxy.sh
```

使用 **8080**（可在 `.env` 用 `PANEL_PROXY_PORT` 修改）反代本机 8000。安全组放行 **8080**，不是公网直连 8000。

### `reality-inbound.generated.json` 不存在

**原因**：文件由脚本生成，不提交 Git。

**处理**：

```bash
cd /opt/heaven_ladder && sudo bash scripts/configure-reality-inbound.sh
```

## 面板与账号

### 没有默认 `admin` / `admin`

新版 Marzban 安装后需创建管理员：

```bash
sudo marzban cli admin create --sudo
# 或
sudo marzban cli admin import-from-env   # 若 .env 中配置了 SUDO_USERNAME/PASSWORD
```

### 忘记密码

```bash
sudo marzban cli admin list
sudo marzban cli admin update -u <用户名>
```

## Hosts（主机设置）

| 字段 | 建议 |
|------|------|
| Address | 填 **`8.209.239.243`** 等公网 IP，或确认 `{SERVER_IP}` 解析正确 |
| Port（高级） | `443` |
| SNI（高级） | 与 Core 中 `serverNames` 一致，如 `www.microsoft.com` |

**勿留空的第二条 Host**，勿保留未使用的 Shadowsocks Host，否则订阅会出现 1080 或错误 IP 节点。

## 用户与 Core

| 项 | 说明 |
|----|------|
| 用户 Flow | **Users → Vless → 右侧 ⋮** → `xtls-rprx-vision`（主界面无 Flow 下拉） |
| Core inbounds | 单节点仅保留 **VLESS TCP REALITY**；删除未使用的 **Shadowsocks 1080** |
| Restart Core | 改 Core / Hosts / 用户后必须重启 |

## 客户端 — 订阅 URL

| 客户端 | URL 格式 |
|--------|----------|
| Clash Verge Rev | `http://<IP>:8080/sub/<token>/clash-meta` |
| Shadowrocket / v2rayNG | `http://<IP>:8080/sub/<token>` |

**不要用**公网 `8000` 拉订阅（除非自行解决 SSL/反代）。

## 客户端 — Clash Verge 开了代理仍上不了网

### 日志出现 `dial DIRECT --> www.youtube.com`

**原因**：流量未走节点（规则/策略组/merge 配置错误）。

**处理**：

1. 关闭会把 `MATCH` 指向空策略组的 **订阅扩展配置**（旧版称 merge）。
2. 模式选 **全局**，**手动选择** VLESS 节点（勿只依赖 ♻️ Automatic）。
3. 开启 **TUN** 或系统代理。
4. 单节点阶段使用 [client/clash-verge-rules-override.yaml](../client/clash-verge-rules-override.yaml)，勿用 merge 模板。
5. `MATCH` 勿加引号：用 `MATCH,♻️ Automatic`，勿用 `MATCH,"♻️ Automatic"`（会报 `proxy not found`）。
6. 规则模式下须在 **代理** 页选中节点，否则显示「暂无激活的代理节点」。

### 订阅里 `flow: ''`

未设置 Flow → 在面板用户 **Vless ⋮** 中设置 `xtls-rprx-vision` 后更新订阅。

### 订阅里 `server` 不是 VPS 公网 IP

检查 **Hosts** Address，删除错误 Host（如其它 VPS IP）。

## 网络检查命令

```bash
# VPS
sudo ss -tlnp | grep -E '443|8000|8080'
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/dashboard/
curl -sS -o /dev/null -w "%{http_code}\n" http://<公网IP>:8080/dashboard/
```

```powershell
# Windows（不开代理）
Test-NetConnection <公网IP> -Port 443
Test-NetConnection <公网IP> -Port 8080
```

## 仅 IPv6 家庭网络

- `ADMIN_WHITELIST_IP` 仅 IPv4 时，UFW/安全组对 8000 的白名单可能无效。
- 推荐使用 `setup-panel-proxy.sh` + 安全组放行 **8080/443**，订阅用公网 IP + 8080。
- 临时管理面板可用 SSH 隧道：`ssh -N -L 8000:127.0.0.1:8000 root@<VPS>` → `http://127.0.0.1:8000/dashboard/`。

## 相关文档

- [panel-and-subscription.md](panel-and-subscription.md)
- [client-setup.md](client-setup.md)
- [aliyun-setup.md](aliyun-setup.md)
