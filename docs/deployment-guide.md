# 部署指导书

本文档指导你从零开始，将本套件部署到华为云。

## 1. 前置条件

| 项 | 说明 |
|---|---|
| 华为云账号 | 已完成实名认证，账号下有默认项目权限 |
| Access Key / Secret Key | 在「我的凭证」页面创建，具有 RDS / VPC / CES / SMN / KMS / 凭据管理服务权限 |
| Terraform | ≥ 1.5（推荐 1.9+），安装方式见 [terraform.io/downloads](https://www.terraform.io/downloads) |
| 本仓库 | 已克隆到本地或 CI 环境 |

## 2. 准备凭据

Terraform 通过环境变量读取华为云凭据（**不写入文件**）：

```bash
export HW_ACCESS_KEY="<你的 Access Key>"
export HW_SECRET_KEY="<你的 Secret Key>"
```

> 生产环境建议使用临时凭据（Security Token）或 IAM 委托，避免长期 AK/SK 泄露风险。

## 3. 初始化

```bash
cd infra
terraform init
```

## 4. 部署示例：MySQL 高可用集群

```bash
cd infra

# 查看将要创建的资源
terraform plan -var-file=../examples/mysql-cluster-existing-vpc.tfvars

# 执行部署
terraform apply -var-file=../examples/mysql-cluster-existing-vpc.tfvars
```

预期输出：`Apply complete! Resources: N added, 0 changed, 0 destroyed.`，随后 `terraform output` 显示实例 ID、私网 IP、端口。

## 5. 部署其他场景

其他场景见 `examples/` 下对应的 tfvars 文件，将 `terraform apply` 的 `-var-file` 替换即可：

| 场景 | 命令 |
|---|---|
| PostgreSQL 集群 | `terraform apply -var-file=../examples/postgres-cluster-existing-vpc.tfvars` |
| MySQL + 连接代理 | `terraform apply -var-file=../examples/mysql-dbproxy.tfvars` |
| MySQL + 跨区域容灾 | 先填写 `destination_project_id`，再 `terraform apply -var-file=../examples/mysql-cluster-global-db.tfvars` |
| MySQL + 从备份恢复 | 先创建手动备份并获得备份 ID，填入 `restore_backup_id`，再 apply |
| 监控看板 + 告警 | 填入 `alarm_notify_email` 后 apply（默认部署时已开启监控） |

### 5.1 连接代理（MySQL）

部署后查看代理地址：

```bash
terraform output proxy_address
```

代理端口与主实例一致（默认 3306）。应用连接地址改为代理地址，即可复用连接池。

### 5.2 跨区域容灾

1. 在目标区域（如 `cn-south-1`）控制台「我的凭证」获取项目 ID。
2. 在 tfvars 中填写 `destination_project_id` 与 `destination_region`。
3. apply 后，主实例的自动备份将按保留期复制到目标区域；区域级故障时可到目标区域以备份重建实例。

### 5.3 从备份恢复

1. 对已部署实例在控制台创建手动备份，记录备份 ID。
2. 在 tfvars 中填写 `restore_backup_id`。
3. apply 后创建 `-restored` 后缀的新实例，数据与备份一致。

## 6. 使用方法与验证

### 6.1 获取连接信息

```bash
cd infra
terraform output rds_private_ips     # 主实例私网 IP
terraform output rds_port            # 端口（3306 / 5432）
terraform output db_secret_name      # 凭据名称（凭据管理服务）
```

密码与连接串通过**凭据管理服务**获取（不落盘到文件）：

```bash
# 任选其一：
# 1) 控制台：凭据管理服务 → 搜索 db_secret_name → 查看明文
# 2) 命令行 SDK：调用 GetSecret 接口读取 secret_text（JSON 含 username/password/host/port）
```

### 6.2 从同 VPC 内主机连接

```bash
IP="$(terraform output -raw rds_private_ips | tr -d '[]" ' | cut -d, -f1)"
PORT="$(terraform output -raw rds_port)"

# MySQL
mysql -h "$IP" -P "$PORT" -u root -p

# PostgreSQL
psql -h "$IP" -p "$PORT" -U root -d postgres
```

> 连接主机需与数据库实例同 VPC，且已加入该安全组的放行范围。

### 6.3 验证监控与告警

1. 打开云监控控制台 → 仪表盘，找到 `${name}-dashboard-${environment}`，应能看到 CPU 使用率与磁盘使用率曲线。
2. 打开云监控 → 告警规则。按需在控制台创建规则：选择 SYS.RDS 命名空间、指标 `rds001_cpu_util`（CPU）与 `rds039_disk_util`（磁盘），维度填实例 ID；推荐阈值 CPU ≥ 80%、磁盘 ≥ 85%。
3. 若需要通知，创建 SMN 主题并绑定到告警规则的告警通知，订阅后触发阈值即会收到邮件/短信。

### 6.4 验证只读副本

```bash
terraform output rds_read_replica_ids   # 只读副本实例 ID 列表
```

在 RDS 控制台应能看到对应只读实例，状态为「正常」。

## 7. 清理资源

```bash
cd infra
terraform destroy -var-file=../examples/mysql-cluster-existing-vpc.tfvars
```

> `terraform destroy` 会释放全部本套件创建的云资源（含数据库实例、只读副本、代理等），避免残留。
> 手动备份（`enable_manual_backup=true` 时创建）与跨区域备份如需彻底清除，请在控制台确认后再删除，防止误删恢复数据。

## 8. 常见问题

| 问题 | 处理 |
|---|---|
| `Invalid authentication credentials` | 检查 `HW_ACCESS_KEY` / `HW_SECRET_KEY` 是否正确、账号是否有对应服务权限 |
| `No available flavor` | `instance_flavor` 需选用当前区域实际可售的规格，可到 RDS 售卖页确认 |
| 只读副本创建失败 | 确认主实例状态为「正常」且非临时变更中；副本数量上限受区域配额限制 |
| 代理创建失败 | 连接代理仅 MySQL 引擎支持；确认 `enable_proxy` 仅在 engine=MySQL 时开启 |
| 监控无数据 | 等待 5-10 分钟指标采集；确认告警/看板里维度选择的是当前实例 ID |

## 9. 参考

- [华为云 RDS 产品文档](https://support.huaweicloud.com/rds/)
- [huaweicloud Terraform Provider](https://registry.terraform.io/providers/huaweicloud/huaweicloud/latest/docs)
- [云监控服务 CES 文档](https://support.huaweicloud.com/ces/)