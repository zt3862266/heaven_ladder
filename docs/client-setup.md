# 客户端配置指南

所有设备使用 **同一个 Marzban 订阅 URL**，实现多节点自动同步。

## 获取订阅链接

1. 登录 Marzban 面板 → **Users**
2. 创建用户（或选择已有用户）
3. 点击用户行 → 复制 **Subscription URL**
4. 建议启用 **Subscription Token**（Settings → Subscription），防止链接泄露

## 电脑 — Clash Verge Rev（Windows / macOS）

### 安装

- GitHub: https://github.com/clash-verge-rev/clash-verge-rev/releases
- 下载对应系统的安装包并安装

### 导入订阅

1. 打开 Clash Verge Rev
2. **Profiles** → 粘贴订阅 URL → **Import**
3. 选中导入的配置 → 点击 **Enable**

### 自动选路

1. 将 [client/clash-verge-merge.yaml](../client/clash-verge-merge.yaml) 的内容配置为 Merge
2. **Settings** → **Clash Fields** → 启用 merge
3. 或在 Profiles 页面 → 右键订阅 → **Extend Config** → 粘贴 merge 内容

### 推荐模式

| 模式 | 用途 |
|------|------|
| **Rule（规则）** | 日常：国内直连，外网走代理 |
| **Global（全局）** | 调试：所有流量走节点 |

### 策略组

- **🚀 自动选择** — 默认使用，按延迟自动选最快节点
- **🔰 故障转移** — 当前节点不可用时自动切换
- **🇸🇬 新加坡 / 🇯🇵 日本 / 🇺🇸 美国** — 手动指定区域

## 手机 — iOS（Shadowrocket）

### 安装

- App Store 搜索 **Shadowrocket**（需非国区 Apple ID，约 ¥30）

### 导入

1. 复制 Marzban 订阅 URL
2. Shadowrocket → 首页右上角 **+** → **类型选 Subscribe**
3. 粘贴 URL → **完成**
4. 点击订阅 → **更新** → 选择节点 → 开启连接

### 推荐设置

- **全局路由** → **配置**（等同 Rule 模式）
- 开启 **自动测试** 和 **按延迟排序**

## 手机 — Android（v2rayNG）

### 安装

- GitHub: https://github.com/2dust/v2rayNG/releases
- 或 Google Play 搜索 v2rayNG

### 导入

1. 打开 v2rayNG → 右上角 **+** → **Import config from Clipboard**（先复制订阅 URL）
2. 或 **Subscription setting** → **+** → 粘贴 URL → 更新

### 推荐设置

- 路由设置 → **绕过局域网和大路**
- 延迟测试 → 选择最低延迟节点

## Android 备选 — Clash Meta for Android

- GitHub: https://github.com/MetaCubeX/ClashMetaForAndroid/releases
- 导入方式与 Clash Verge Rev 类似

## 节点 Host 命名（重要）

在 Marzban 面板 → **Hosts** 中，为每个节点设置 Remark：

| 节点 | 建议 Remark |
|------|------------|
| 新加坡 | 🇸🇬 新加坡 |
| 日本 | 🇯🇵 日本 |
| 美国 | 🇺🇸 美国 |

命名一致后，Clash merge 配置中的策略组才能正确匹配节点。

## 验证

导入并连接后，访问以下站点确认：

- https://www.google.com
- https://www.youtube.com
- https://ip.sb （应显示 VPS 所在国家的 IP）

## 常见问题

| 问题 | 排查 |
|------|------|
| 订阅更新失败 | 检查订阅 URL 是否有效、Token 是否正确 |
| 所有节点超时 | 运行 `bash scripts/health-check.sh` 检查 VPS 443 端口 |
| 能连但很慢 | 切换到「自动选择」策略组，或换区域节点 |
| 部分 App 不走代理 | 确认使用 Rule 模式；系统代理模式下部分 App 需 TUN 模式 |
