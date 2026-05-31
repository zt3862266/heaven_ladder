# 管理面板选型说明

## 决策：Marzban

| 维度 | Marzban | 3X-UI |
|------|---------|-------|
| 多节点管理 | 原生支持 Node 集群 | 每台独立，需 subconverter 合并 |
| 订阅 URL | 单一订阅，自动同步所有节点 | 每节点一个订阅 |
| 用户管理 | 内置多用户、流量限制 | 内置 |
| 部署方式 | Docker 一键 | Docker / 二进制 |
| 社区活跃度 | 高 | 高 |
| 本项目支持 | 完整脚本 | 未包含 |

**结论**：Heaven Ladder 采用 **Marzban** 作为唯一管理面板。

## 安装命令

```bash
sudo bash deploy.sh master   # 主控
sudo bash deploy.sh node     # Worker
```

官方文档：https://gozargah.github.io/marzban/en/docs/introduction
