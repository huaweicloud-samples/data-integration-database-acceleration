# 架构说明

## 1. 总体架构

本套件以 **基础设施即代码（IaC）** 方式，将托管关系型数据库集群的**初始化、预置与持续运维**固化为可复用的 Terraform 模块。面向从商业数据库平滑切换到云上托管数据库的团队，降低选型、搭建、监控与运维的重复工作。

```
┌──────────────────────────────────────────────────────────────────────┐
│                        运维入口（两种方式）                              │
│  ① 命令行：terraform plan/apply（本仓库 scripts/deploy.sh）             │
│  ② CI 流水线：Jenkins / 其他 CI 工具调用同一套模块                       │
└──────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│                         基础设施层（VPC / 子网 / 安全组）                 │
│  • 私有网络隔离：数据库仅允许 VPC 内网访问                              │
│  • 安全组：按端口（3306/5432）最小化放行                                │
└──────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│                       数据库集群层（RDS 主备 + 只读副本）                 │
│  • 高可用主实例（跨可用区主备）                                         │
│  • 只读副本（弹性扩展读能力）                                           │
│  • 参数组（引擎调优：慢查询/死锁/超时等）                               │
│  • KMS 加密存储 + 凭据管理服务托管连接串                                │
└──────────────────────────────────────────────────────────────────────┘
        │                        │                        │
        ▼                        ▼                        ▼
┌──────────────┐    ┌───────────────────┐    ┌──────────────────────┐
│ 连接代理层     │    │  可观测层           │    │  容灾与恢复层          │
│ RDS 数据库代理 │    │  CES 仪表盘+告警    │    │  跨区域备份 + 备份恢复  │
│ 连接池复用     │    │  SMN 通知           │    │  区域级故障容灾         │
└──────────────┘    └───────────────────┘    └──────────────────────┘
```

## 2. 资源清单

| Terraform 资源 | 用途 | 随实例创建 |
|---|---|---|
| `huaweicloud_vpc` / `huaweicloud_vpc_subnet` | 私有网络与子网 | 否（随账号免费） |
| `huaweicloud_networking_secgroup` + 规则 | 数据库安全组 | 否 |
| `huaweicloud_rds_instance` | 高可用主实例（主备） | 是 |
| `huaweicloud_rds_read_replica_instance` | 只读副本 | 是 |
| `huaweicloud_rds_parametergroup` | 引擎参数组 | 否 |
| `huaweicloud_kms_key` | 存储加密密钥 | 否（密钥管理服务免费额度内） |
| `huaweicloud_csms_secret` | 数据库连接凭据 | 否 |
| `huaweicloud_rds_mysql_proxy` | 连接代理（连接池复用，仅 MySQL） | 是 |
| `huaweicloud_ces_dashboard` / `_widget` | 监控仪表盘 | 否 |
| `huaweicloud_ces_alarmrule` | 告警规则 | 否 |
| `huaweicloud_smn_topic` / `_subscription` | 告警通知 | 否 |
| `huaweicloud_rds_cross_region_backup_strategy` | 跨区域容灾备份 | 是（按备份容量） |
| `huaweicloud_rds_backup` | 手动备份 | 是（按备份容量） |

## 3. 关键设计决策

### 3.1 高可用主备 + 只读副本

- 主实例使用主备高可用（不同可用区），最大程度避免单点故障。
- 只读副本数量通过 `read_replica_count` 控制，0 表示不创建，用于扩展读能力。
- 副本规格默认与主实例一致，可通过 `read_replica_flavor` 单独指定。

### 3.2 凭据管理

- 数据库管理员密码默认由模块生成随机强密码，写入**凭据管理服务**（以 JSON 格式保存连接串：用户名/密码/主机/端口）。
- 需要外部导入密码时，设置 `db_password` 变量即可（此时不再创建凭据）。

### 3.3 存储加密

- 默认自动创建 KMS 密钥并用于云盘加密（`disk_encryption_id`）。
- 已有密钥时传 `kms_key_id` 复用。

### 3.4 数据库代理（连接池）

- MySQL 引擎支持创建 RDS 数据库代理，实现连接池复用与读写分离，缓解大量短连接对主库的压力。
- PostgreSQL 引擎暂不支持代理，可依赖应用层连接池（如 PgBouncer）或直接使用只读副本。

### 3.5 监控与告警

- 创建 CES 仪表盘，展示 CPU 使用率与磁盘使用率等核心指标。
- 建议在云监控控制台创建两条告警规则：CPU ≥ 80%（持续 5 个周期）、磁盘使用率 ≥ 85%（持续 1 个周期），并绑定 SMN 主题实现邮件/短信通知。

### 3.6 容灾与恢复

- **跨区域备份**：`enable_cross_region_backup = true` 时，自动备份复制到目标区域（`destination_region`），用于区域级故障恢复。
- **从备份恢复**：`restore_backup_id` 传入备份 ID 时，创建并部署一个从该备份恢复的新实例。

## 4. 场景组合（examples）

| 示例文件 | 场景 | 关键开关 |
|---|---|---|
| `mysql-cluster-existing-vpc.tfvars` | MySQL 高可用集群 | 引擎 MySQL + 只读 1 |
| `postgres-cluster-existing-vpc.tfvars` | PostgreSQL 高可用集群 | 引擎 PostgreSQL + 只读 1 |
| `mysql-dbproxy.tfvars` | MySQL 集群 + 连接代理 | `enable_proxy=true` |
| `mysql-cluster-global-db.tfvars` | MySQL 集群 + 跨区域容灾 | `enable_cross_region_backup=true` |
| `mysql-cluster-latest-snapshot.tfvars` | 从备份恢复 | `restore_backup_id=<BACKUP_ID>` |
| `mysql-monitoring.tfvars` | 集群 + 监控告警 | `enable_monitoring=true` + 邮箱 |

> PostgreSQL 对应场景只需将 `engine` 改为 `PostgreSQL` 并调整 `engine_version`，其余模块逻辑一致。

## 5. 安全说明

- 数据库默认**不绑定公网 IP**，仅 VPC 内网访问；安全组仅放行 VPC 内网段。
- 凭据不写入 Terraform 状态明文：密码由模块生成并保存至凭据管理服务，状态中仅保存凭据名称。
- 存储默认加密（KMS）。
- 如需公网访问，请在安全组按需放行并评估暴露面。