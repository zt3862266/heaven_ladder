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

## 端口说明（重要）

| 端口 | 用途 |
|------|------|
| **443** | 代理流量（REALITY），需对 `0.0.0.0/0` 开放 |
| **8000** | Marzban 仅本机 `127.0.0.1`（无 SSL 时无法改 0.0.0.0） |
| **8080** | Nginx 公网反代 → 面板与订阅（`setup-panel-proxy.sh`） |

## 快速开始

### 前置条件

- 阿里云海外 VPS（Ubuntu 22.04 / Debian 12），至少 1 台主控 + 1 台 Worker
- 安全组：**443/tcp**、**8080/tcp** 对客户端可达；**不要**依赖公网直连 8000
- 在 `.env` 填写 `MASTER_IP`（主控公网 IP）

### Day 1 — 主控节点

```bash
git clone <your-repo-url> /opt/heaven_ladder
cd /opt/heaven_ladder

cp .env.example .env
nano .env   # 填写 MASTER_IP

sudo bash deploy.sh master
```

`deploy.sh master` 依次执行：系统基线 → 安装 Marzban → REALITY → **面板反代 (8080)**。

安装后：

```bash
sudo marzban cli admin create --sudo
```

- 面板：`http://<主控IP>:8080/dashboard/`
- Clash 订阅：`http://<主控IP>:8080/sub/<token>/clash-meta`

详细说明：[docs/panel-and-subscription.md](docs/panel-and-subscription.md)  
踩坑汇总：[docs/troubleshooting.md](docs/troubleshooting.md)

### Day 2 — Worker 节点

```bash
git clone <your-repo-url> /opt/heaven_ladder
cd /opt/heaven_ladder
sudo bash deploy.sh node
```

主控面板 → **Node Settings** → **Add New Marzban Node**。

### Day 3 — 客户端

见 [docs/client-setup.md](docs/client-setup.md)。Clash 规则模式覆写：[client/clash-verge-rules-override.yaml](client/clash-verge-rules-override.yaml)。

## 目录结构

| 路径 | 说明 |
|------|------|
| [scripts/](scripts/) | VPS 部署脚本 |
| [config/](config/) | XRay inbound 模板、节点清单 |
| [client/](client/) | Clash Verge 规则覆写与多节点 merge 模板 |
| [docs/](docs/) | 安全组、面板、客户端、故障排查 |

## 常用命令

```bash
sudo bash deploy.sh master        # 完整主控部署
sudo bash deploy.sh panel-proxy   # 仅配置 8080 反代
sudo bash scripts/configure-reality-inbound.sh
bash scripts/health-check.sh
sudo bash deploy.sh update
```

## 管理面板

采用 **Marzban**（非 3X-UI）：多节点统一管理、单一订阅 URL。见 [docs/panel-decision.md](docs/panel-decision.md)。

## 合规提示

请确保用途符合当地法律法规及阿里云服务条款。本仓库仅提供个人技术部署工具，用于合法访问公开互联网资源。
