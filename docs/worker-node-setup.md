# Worker 节点接入指南

每台 Worker VPS 需要 **独立的 REALITY 密钥**，不可与主控或其他节点共用。

## 步骤

### 1. 基础部署

```bash
git clone <repo> /opt/heaven_ladder && cd /opt/heaven_ladder
cp .env.example .env   # 可选，用于 REALITY 伪装目标
sudo bash deploy.sh node
```

### 2. 生成独立 REALITY 密钥

```bash
sudo bash scripts/generate-reality-keys.sh jp-backup
# 输出 config/nodes/jp-backup-reality.env 和 jp-backup-inbound.json
```

### 3. 在主控面板注册节点

1. 主控面板 → **Node Settings** → **Add New Marzban Node**
2. 填写：
   - **Name**: `jp-backup`（与 generate 脚本参数一致）
   - **Address**: Worker 公网 IP
   - **Port**: `62050`
3. 复制 **Certificate**
4. 在 Worker 上：

```bash
nano /var/lib/marzban-node/ssl_client_cert.pem
# 粘贴 Certificate，保存

cd ~/Marzban-node && docker compose up -d
```

5. 回到面板确认状态为 **Connected**

### 4. 配置 Worker 的 REALITY Inbound

1. 主控面板 → **Node Settings** → 选中 `jp-backup` → **Core Settings**
2. 在 `inbounds` 数组开头粘贴 `config/nodes/jp-backup-inbound.json` 内容
3. **Save** → **Restart Core**

### 5. 添加 Host

1. 主控面板 → **Hosts** → **Add Host**
2. 填写：
   - **Inbound**: VLESS TCP REALITY
   - **Remark**: `🇯🇵 日本`（与客户端策略组匹配）
   - **Address**: Worker 公网 IP
   - **Port**: 443

### 6. 验证

```bash
# 在本地或主控运行
bash scripts/health-check.sh
```

客户端刷新订阅，应看到新节点出现在对应策略组中。

## 节点清单模板

复制并按实际情况填写：

```bash
cp config/nodes/inventory.example.json config/nodes/inventory.json
nano config/nodes/inventory.json
```

## 注意事项

- 每台 Worker 的 `privateKey` 和 `shortId` 必须不同
- Worker 不暴露 Marzban 面板（8000 端口）
- 主控安全组需允许 Worker IP 访问 62050/tcp
- 建议在 2 个以上区域部署节点以实现容灾
