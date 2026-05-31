# 客户端配置指南

所有设备使用 **同一个 Marzban 订阅 URL**（经 `setup-panel-proxy.sh` 生成的前缀）。

## 订阅 URL 格式

将 `<IP>`、`<token>` 替换为实际值（主控部署后可在面板 **Users** 中复制）：

| 客户端 | 订阅地址 |
|--------|----------|
| **Clash Verge Rev** | `http://<IP>:8080/sub/<token>/clash-meta` |
| **Shadowrocket / v2rayNG** | `http://<IP>:8080/sub/<token>` |

**注意**：

- 不要用 `/sub/<token>` 导入 Clash（那是 Base64 通用链接，不是 YAML）。
- 不要用公网 `:8000`（Marzban 仅监听本机）。

## 获取订阅链接

1. 登录 `http://<IP>:8080/dashboard/`
2. **Users** → 用户 → 复制 **Subscription URL**
3. Clash 用户请在链接末尾加上 `/clash-meta`（若面板未自动带上）
4. 建议开启 **Settings → Subscription Token**

## 电脑 — Clash Verge Rev（Windows / macOS）

### 安装

- https://github.com/clash-verge-rev/clash-verge-rev/releases

### 导入与连接（单节点推荐）

1. **订阅** → 粘贴 `.../clash-meta` → 导入 → 更新
2. **不要**绑定 [clash-verge-merge.yaml](../client/clash-verge-merge.yaml)（仅多区域 Worker 时使用）
3. **规则模式**：将 [client/clash-verge-rules-override.yaml](../client/clash-verge-rules-override.yaml) 全文粘贴到  
   **订阅 → 右键该配置 → 编辑扩展配置**（推荐，避免影响其他订阅）  
   或 **设置 → 全局扩展配置**（仅有一个订阅时）
4. 保存后 **重新加载配置**（🔥）；**更新订阅**后若规则失效，检查扩展配置是否仍在
5. 模式：**规则** 或 **全局** 均可  
   - **规则**：须在左侧 **代理** 页选中 `♻️ Automatic` 或 VLESS 节点（否则首页显示「暂无激活的代理节点」）  
   - **全局**：代理页手动选 **VLESS** 即可
6. 开启 **TUN** 或系统代理
7. 验证：https://ip.sb 应显示 VPS 地区 IP

`MATCH` 规则 **不要**写成 `MATCH,"♻️ Automatic"`（带引号会报 `proxy not found`）。

### Clash Verge Rev 1.7+ 扩展配置位置

- **设置** → **全局扩展配置**（对所有订阅生效）
- **订阅** → 右键该配置 → **编辑扩展配置**（仅该订阅）

旧版「Merge / Clash 字段」已改名，见 [官方 Extend 文档](https://clash-verge-rev.github.io/guide/extend.html)。

### 日志里 `dial DIRECT`

表示未走代理 → 见 [troubleshooting.md](troubleshooting.md)。

### 规则覆写模板

见 [client/clash-verge-rules-override.yaml](../client/clash-verge-rules-override.yaml)。

## 手机 — iOS（Shadowrocket）

1. 复制 `http://<IP>:8080/sub/<token>`
2. **Subscribe** 类型导入 → 更新 → 选 VLESS 节点 → 连接

## 手机 — Android

- **Clash Meta**：同电脑，使用 `/clash-meta`
- **v2rayNG**：使用无后缀 `/sub/<token>`

## 多节点时的 Host 命名

在 Marzban **Hosts** 为各区域设置 Remark（与 [clash-verge-merge.yaml](../client/clash-verge-merge.yaml) 中组名一致）：

| 节点 | 建议 Remark |
|------|------------|
| 新加坡 | 🇸🇬 新加坡 |
| 日本 | 🇯🇵 日本 |
| 美国 | 🇺🇸 美国 |

## 验证

- https://www.google.com
- https://ip.sb

## 常见问题

| 问题 | 排查 |
|------|------|
| 订阅失败 | 安全组 **8080**、`setup-panel-proxy.sh` 是否已运行 |
| Clash 无效 | 是否用 `/clash-meta`；是否 `dial DIRECT` |
| 节点超时 | `ss -tlnp \| grep 443`；Hosts Address 是否为公网 IP |
| flow 为空 | 用户 **Vless ⋮** → `xtls-rprx-vision` |

完整排查：[troubleshooting.md](troubleshooting.md)
