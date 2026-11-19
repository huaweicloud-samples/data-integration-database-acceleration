# data-integration-database-acceleration

[![License](https://img.shields.io/badge/License-MIT%20No%20Attribution-blue.svg)](LICENSE)
[![Huawei Cloud](https://img.shields.io/badge/Huawei%20Cloud-Terraform-red.svg)](https://registry.terraform.io/providers/huaweicloud/huaweicloud/latest)

数据库集群自动化部署套件：以 IaC 一键完成托管数据库的初始化、预置、连接代理、监控、容灾与恢复。

## 1. 简介

本套件面向从商业数据库平滑切换到云上托管数据库的团队，把数据库集群从「规划、搭建、调优、监控、容灾」整套运维工作固化为可复用的 Terraform 模块。开箱即用，一条命令得到生产级配置：高可用主备 + 只读副本、参数组调优、存储加密、凭据托管、监控看板与告警、跨区域容灾备份、备份恢复。

## 2. 目录

- [1. 简介](#1-简介)
- [2. 目录](#2-目录)
- [3. 架构图](#3-架构图)
- [4. 方案亮点](#4-方案亮点)
- [5. 涉及云服务](#5-涉及云服务)
- [6. 前置条件](#6-前置条件)
- [7. 快速开始](#7-快速开始)
- [8. 分步部署](#8-分步部署)
- [9. 使用方法](#9-使用方法)
- [10. 清理资源](#10-清理资源)
- [11. 详细说明](#11-详细说明)
- [12. 依赖](#12-依赖)
- [13. FAQ](#13-faq)
- [14. 贡献指南](#14-贡献指南)
- [15. 许可证](#15-许可证)
- [16. 联系方式](#16-联系方式)
- [17. 创建者与维护者](#17-创建者与维护者)

## 3. 架构图

详见 [docs/architecture.md](docs/architecture.md)。

```
基础设施层（VPC/子网/安全组）
        ↓
数据库集群层（RDS 主备 + 只读副本 + 参数组 + KMS 加密 + 凭据管理）
        ↓
┌─────────────┬──────────────────┬────────────────┐
│ 连接代理     │ 监控告警           │ 容灾与恢复       │
│ (MySQL Proxy)│ CES 仪表盘+告警   │ 跨区域备份+恢复  │
└─────────────┴──────────────────┴────────────────┘
```

## 4. 方案亮点

- **一键预置**：Terraform 模块化，`apply` 一条命令得到生产级集群。
- **高可用**：主备跨可用区 + 只读副本按需扩展。
- **开箱可观测**：CES 仪表盘展示核心指标；告警规则可在云监控控制台一键创建并绑定通知。
- **安全默认**：存储 KMS 加密、凭据托管、仅内网访问。
- **可选扩展**：MySQL 连接代理（连接池复用）、跨区域备份与备份恢复，以示例 tfvars 提供，按需启用。

> 说明：默认集群链路（预置、监控、安全）已随本套件完成端到端验证；连接代理、跨区域备份、从备份恢复为可选扩展能力，示例模板提供配置入口，启用前请按部署指导书自行验证。

## 5. 涉及云服务

- 关系型数据库服务 RDS
- 虚拟私有云 VPC
- 数据加密服务 DEW（KMS + 凭据管理）
- 云监控服务 CES
- 消息通知服务 SMN

> 清理资源：部署完成后可通过 `terraform destroy` 释放本套件创建的全部云资源，避免残留。

## 6. 前置条件

| 项 | 说明 |
|---|---|
| 华为云账号 | 已完成实名认证 |
| Access Key / Secret Key | 在「我的凭证」页面创建，具有 RDS / VPC / CES / SMN / DEW 权限 |
| Terraform | ≥ 1.5（推荐 1.9+） |
| Region | 默认 `cn-north-4`，可在变量中修改 |

## 7. 快速开始

```bash
git clone <your-repo-url> && cd <new-repo-name>

export HW_ACCESS_KEY="<你的 Access Key>"
export HW_SECRET_KEY="<你的 Secret Key>"

cd infra
terraform init
terraform apply -var-file=../examples/mysql-cluster-existing-vpc.tfvars
```

或使用一键脚本：

```bash
./scripts/deploy.sh ../examples/mysql-cluster-existing-vpc.tfvars
```

## 8. 分步部署

### 1. 初始化

```bash
cd infra
terraform init
```

### 2. 规划参数

编辑 `examples/` 下的 tfvars 文件，关键项包括：

| 参数 | 说明 | 默认 |
|---|---|---|
| `region` | 部署区域 | `cn-north-4` |
| `name` | 资源名前缀 | `dat-poc` |
| `engine` | 引擎：`MySQL` / `PostgreSQL` | `MySQL` |
| `engine_version` | 引擎版本 | MySQL `8.0` / PG `14` |
| `instance_flavor` | 主实例规格 | 按区域调整 |
| `read_replica_count` | 只读副本数 | `1` |
| `enable_proxy` | 是否创建连接代理（仅 MySQL） | `false` |
| `enable_cross_region_backup` | 是否跨区域备份 | `false` |
| `alarm_notify_email` | 告警邮箱（空则不创建订阅） | `""` |

### 3. 执行部署

```bash
terraform plan -var-file=../examples/mysql-cluster-existing-vpc.tfvars
terraform apply -var-file=../examples/mysql-cluster-existing-vpc.tfvars
```

其他场景：

```bash
# PostgreSQL 集群
terraform apply -var-file=../examples/postgres-cluster-existing-vpc.tfvars

# MySQL + 连接代理
terraform apply -var-file=../examples/mysql-dbproxy.tfvars

# MySQL + 跨区域容灾（先填 destination_project_id）
terraform apply -var-file=../examples/mysql-cluster-global-db.tfvars

# MySQL + 从备份恢复（先填 restore_backup_id）
terraform apply -var-file=../examples/mysql-cluster-latest-snapshot.tfvars

# 监控看板 + 告警（填入邮箱）
terraform apply -var-file=../examples/mysql-monitoring.tfvars
```

### 4. 查看输出

```bash
terraform output
```

输出包含：实例 ID、私网 IP、端口、只读副本 ID、凭据名称、代理地址、监控看板 ID。

## 9. 使用方法

1. **查看资源**：`terraform state list` 应能看到 RDS 实例与只读副本。
2. **连接数据库**：从同 VPC 主机执行
   ```bash
   mysql -h <rds_private_ips> -P <rds_port> -u root -p
   ```
   密码从凭据管理服务获取（控制台或 SDK）。
3. **验证监控**：云监控 → 仪表盘 → `${name}-dashboard-${environment}` 应有 CPU / 磁盘曲线；告警规则列表应有 CPU 与存储两条规则。
4. **验证代理（如启用）**：`terraform output proxy_address` 获得地址，应用改为代理地址连接。
5. **验证只读副本**：RDS 控制台应看到 `-ro-1` 只读实例，状态正常。
6. **手动验证脚本**：`./scripts/verify.sh` 输出实例状态与连接信息摘要。

> 部署完成后请按本节步骤自行验证，确认业务功能可用，方可视为交付完成。

## 10. 清理资源

```bash
cd infra
terraform destroy -var-file=../examples/mysql-cluster-existing-vpc.tfvars
```

> 手动备份与跨区域备份如需彻底清除，请在控制台确认后再删除，防止误删恢复数据。

## 11. 详细说明

- **架构与设计决策**：见 [docs/architecture.md](docs/architecture.md)，包含资源清单、高可用、凭据、加密、代理、监控、容灾与恢复等设计说明，以及各场景示例的组合方式。
- **部署指导**：见 [docs/deployment-guide.md](docs/deployment-guide.md)，覆盖前置条件、凭据准备、部署步骤、连接验证、监控告警与清理。
- **模块组织**：`infra/` 下按能力拆分 Terraform 文件——`rds.tf`（集群与只读副本）、`kms.tf`（密钥与凭据）、`proxy.tf`（连接代理）、`monitoring.tf`（看板与告警）、`dr.tf`（跨区域备份）、`backup.tf`（手动备份与恢复）。
- **示例场景**：`examples/` 提供 6 个 tfvars，分别对应 MySQL / PostgreSQL 高可用集群、连接代理、跨区域容灾、从备份恢复、监控看板与告警。

## 12. 依赖

- [huaweicloud/huaweicloud](https://registry.terraform.io/providers/huaweicloud/huaweicloud) provider `~> 1.94`
- Terraform `>= 1.5`

## 13. FAQ

- **只读副本数量限制**：受区域配额约束，创建失败时请到 RDS 控制台确认配额。
- **PostgreSQL 能用连接代理吗**：连接代理当前仅 MySQL 引擎支持；PostgreSQL 场景可关闭 `enable_proxy` 或使用应用层连接池。
- **没有 VPC 怎么办**：模块默认新建 VPC/子网/安全组；如已有 VPC，可将 `vpc_id` 等改为 data source 形式复用（见 docs/architecture.md §3）。
- **监控没有数据**：指标采集有 5-10 分钟延迟，请稍后刷新；并确认看板维度选择的是当前实例 ID。

## 14. 贡献指南

欢迎提交 Issue 与 Pull Request。请遵循既有代码风格，并在提交前验证 Terraform 配置（`terraform fmt` / `terraform validate`）。

## 15. 许可证

本实践采用 **MIT No Attribution** 许可证。详见 [LICENSE](LICENSE)。

## 16. 联系方式

- **创建者**：dgc-git
- **维护者**：dgc-git
- 交流渠道：通过 GitHub Issues 提交问题与建议

## 17. 创建者与维护者

| 角色 | 信息 |
|---|---|
| **创建者** | dgc-git |
| **维护者** | dgc-git |