# Heaven Ladder

基于 Marzban + XRay 的阿里云海外 VPS 多节点代理部署工具链。  
主力协议：**VLESS + REALITY + XTLS-Vision**，备用协议：**Hysteria2**。

## 架构

```
主控 VPS (Marzban Panel)
  ├── 本地节点: VLESS REALITY :443
  ├── Worker 节点 1 (新加坡)
  ├── Worker 节点 2 (日本)
  └── Worker 节点 N (美国备用)

客户端 (Clash Meta / Shadowrocket / v2rayNG)
  └── 统一订阅 URL → 自动选路 / 故障转移
```

## 快速开始

### 前置条件

- 阿里云海外 VPS（Ubuntu 22.04 / Debian 12），至少 1 台主控 + 1 台 Worker
- 安全组已放行 `443/tcp`（REALITY）、`8443/udp`（Hysteria2 备用，可选）
- 管理面板端口（8000）**仅对你的家庭公网 IP 开放**

### Day 1 — 主控节点

```bash
# 1. 克隆仓库到 VPS
git clone <your-repo-url> /opt/heaven_ladder
cd /opt/heaven_ladder

# 2. 复制并编辑配置
cp .env.example .env
nano .env

# 3. 系统基线（BBR、防火墙、自动更新）
sudo bash scripts/system-baseline.sh

# 4. 安装 Marzban 主控
sudo bash scripts/install-marzban-master.sh

# 5. 配置 VLESS REALITY inbound
sudo bash scripts/configure-reality-inbound.sh
```

安装完成后访问 `http://<主控IP>:8000/dashboard`，默认账号见脚本输出。

### Day 2 — Worker 节点

在每台 Worker VPS 上：

```bash
git clone <your-repo-url> /opt/heaven_ladder
cd /opt/heaven_ladder
sudo bash scripts/system-baseline.sh --skip-panel-port
sudo bash scripts/install-marzban-node.sh
```

然后在 Marzban 面板 → **Node Settings** → **Add New Marzban Node**，按提示粘贴证书。

### Day 3 — 客户端与加固

- 电脑/手机导入 Marzban 订阅链接，见 [docs/client-setup.md](docs/client-setup.md)
- 可选：部署 Hysteria2 备用、Uptime Kuma 监控，见 [docs/operations.md](docs/operations.md)

## 目录结构

| 路径 | 说明 |
|------|------|
| [scripts/](scripts/) | VPS 部署脚本 |
| [config/](config/) | XRay inbound 模板、节点清单 |
| [client/](client/) | Clash Meta 客户端配置模板 |
| [docs/](docs/) | 阿里云安全组、客户端、运维文档 |

## 管理面板选型

本项目采用 **Marzban**（非 3X-UI），原因：

- 多节点统一管理，单一订阅 URL
- 内置用户/流量/订阅管理
- Docker 部署，升级简单

## 合规提示

请确保用途符合当地法律法规及阿里云服务条款。本仓库仅提供个人技术部署工具，用于合法访问公开互联网资源。
