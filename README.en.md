# data-integration-database-acceleration

[![License](https://img.shields.io/badge/License-MIT%20No%20Attribution-blue.svg)](LICENSE)
[![Huawei Cloud](https://img.shields.io/badge/Huawei%20Cloud-Terraform-red.svg)](https://registry.terraform.io/providers/huaweicloud/huaweicloud/latest)

Database cluster automation toolkit: one-click IaC for managed database provisioning, connection proxy, monitoring, disaster recovery, and restore.

## 1. Overview

This toolkit is designed for teams migrating from commercial databases to managed cloud databases. It codifies the entire operational lifecycle — planning, provisioning, tuning, monitoring, and disaster recovery — as reusable Terraform modules. Get a production-grade setup with a single command: HA primary + read replicas, parameter group tuning, storage encryption, secret management, monitoring dashboards and alarms, cross-region backup, and restore.

## 2. Table of Contents

- [1. Overview](#1-overview)
- [2. Table of Contents](#2-table-of-contents)
- [3. Architecture](#3-architecture)
- [4. Highlights](#4-highlights)
- [5. Cloud Services Used](#5-cloud-services-used)
- [6. Prerequisites](#6-prerequisites)
- [7. Quick Start](#7-quick-start)
- [8. Step-by-step Deployment](#8-step-by-step-deployment)
- [9. Usage and Verification](#9-usage-and-verification)
- [10. Cleanup](#10-cleanup)
- [11. Details](#11-details)
- [12. Dependencies](#12-dependencies)
- [13. FAQ](#13-faq)
- [14. Contribution](#14-contribution)
- [15. License](#15-license)
- [16. Contact](#16-contact)
- [17. Creator and Maintainers](#17-creator-and-maintainers)

## 3. Architecture

See [docs/architecture.md](docs/architecture.md) for details.

```
Infrastructure layer (VPC / Subnet / Security Group)
        ↓
Database cluster layer (RDS HA primary + read replicas + parameter group + KMS encryption + secret management)
        ↓
┌─────────────┬──────────────────┬────────────────┐
│ Proxy       │ Monitoring       │ DR & Restore   │
│ (MySQL Proxy)│ CES dashboard+alarms │ cross-region backup+restore │
└─────────────┴──────────────────┴────────────────┘
```

## 4. Highlights

- **One-click provisioning**: reusable Terraform modules — a single `apply` provision a production-grade cluster.
- **High availability**: HA primary across AZs + read replicas scaled on demand.
- **Observable out of the box**: CES dashboards for core metrics; alarm rules are quick to create in the Cloud Eye console with notification binding.
- **Secure by default**: KMS storage encryption, managed secrets, private network only.
- **Optional extensions**: MySQL connection proxy (connection pooling), cross-region backup, and restore-from-backup are provided as example tfvars and enabled on demand.

> Note: the default cluster chain (provisioning, monitoring, security) has been verified end to end with this toolkit. The connection proxy, cross-region backup, and restore-from-backup are optional extensions; the example templates provide configuration entry points. Verify them yourself against the deployment guide before enabling in production.

## 5. Cloud Services Used

- Relational Database Service (RDS)
- Virtual Private Cloud (VPC)
- Data Encryption Workshop (DEW: KMS + secret management)
- Cloud Eye Service (CES)
- Simple Message Notification (SMN)

> Clean up: run `terraform destroy` after deployment to release all cloud resources created by this toolkit and avoid residue.

## 6. Prerequisites

| Item | Description |
|---|---|
| Huawei Cloud account | Real-name verified |
| Access Key / Secret Key | Create in "My Credentials", with RDS / VPC / CES / SMN / DEW permissions |
| Terraform | >= 1.5 (1.9+ recommended) |
| Region | Default `cn-north-4`, configurable via variables |

## 7. Quick Start

```bash
git clone <your-repo-url> && cd <new-repo-name>

export HW_ACCESS_KEY="<your Access Key>"
export HW_SECRET_KEY="<your Secret Key>"

cd infra
terraform init
terraform apply -var-file=../examples/mysql-cluster-existing-vpc.tfvars
```

Or use the one-click script:

```bash
./scripts/deploy.sh ../examples/mysql-cluster-existing-vpc.tfvars
```

## 8. Step-by-step Deployment

### 1. Initialize

```bash
cd infra
terraform init
```

### 2. Plan parameters

Edit the tfvars files under `examples/`. Key parameters:

| Parameter | Description | Default |
|---|---|---|
| `region` | Deployment region | `cn-north-4` |
| `name` | Resource name prefix | `dat-poc` |
| `engine` | Engine: `MySQL` / `PostgreSQL` | `MySQL` |
| `engine_version` | Engine version | MySQL `8.0` / PG `14` |
| `instance_flavor` | Primary instance flavor | adjust per region |
| `read_replica_count` | Number of read replicas | `1` |
| `enable_proxy` | Create connection proxy (MySQL only) | `false` |
| `enable_cross_region_backup` | Cross-region backup | `false` |
| `alarm_notify_email` | Alarm email (empty = no subscription) | `""` |

### 3. Deploy

```bash
terraform plan -var-file=../examples/mysql-cluster-existing-vpc.tfvars
terraform apply -var-file=../examples/mysql-cluster-existing-vpc.tfvars
```

Other scenarios:

```bash
# PostgreSQL cluster
terraform apply -var-file=../examples/postgres-cluster-existing-vpc.tfvars

# MySQL + connection proxy
terraform apply -var-file=../examples/mysql-dbproxy.tfvars

# MySQL + cross-region DR (fill destination_project_id first)
terraform apply -var-file=../examples/mysql-cluster-global-db.tfvars

# MySQL + restore from backup (fill restore_backup_id first)
terraform apply -var-file=../examples/mysql-cluster-latest-snapshot.tfvars

# Monitoring dashboard + alarms (fill email)
terraform apply -var-file=../examples/mysql-monitoring.tfvars
```

### 4. View outputs

```bash
terraform output
```

Outputs include: instance ID, private IPs, port, read replica IDs, secret name, proxy address, dashboard ID.

## 9. Usage and Verification

1. **View resources**: `terraform state list` should show the RDS instance and read replicas.
2. **Connect to database**: from a host in the same VPC,
   ```bash
   mysql -h <rds_private_ips> -P <rds_port> -u root -p
   ```
   Retrieve the password from the secret management service (console or SDK).
3. **Verify monitoring**: Cloud Eye → Dashboards → `${name}-dashboard-${environment}` should show CPU / storage curves; Alarm Rules should list CPU and storage rules.
4. **Verify proxy (if enabled)**: `terraform output proxy_address` for the address; point the application to the proxy address.
5. **Verify read replicas**: RDS console should show a `-ro-1` replica in "normal" state.
6. **Verification script**: `./scripts/verify.sh` prints instance status and connection summary.

> After deployment, please verify against this section yourself to confirm the business functionality works before treating delivery as complete.

## 10. Cleanup

```bash
cd infra
terraform destroy -var-file=../examples/mysql-cluster-existing-vpc.tfvars
```

> Manual backups and cross-region backups, if any, are retained; confirm before deleting them in the console to avoid losing recovery data.

## 11. Details

- **Architecture and design decisions**: see [docs/architecture.md](docs/architecture.md) — resource inventory, HA, secrets, encryption, proxy, monitoring, DR and restore, and scenario combinations.
- **Deployment guide**: see [docs/deployment-guide.md](docs/deployment-guide.md) — prerequisites, credential setup, deployment steps, connection and verification, monitoring, and cleanup.
- **Module organization**: `infra/` splits Terraform files by capability — `rds.tf` (cluster and replicas), `kms.tf` (key and secret), `proxy.tf` (connection proxy), `monitoring.tf` (dashboard and alarms), `dr.tf` (cross-region backup), `backup.tf` (manual backup and restore).
- **Example scenarios**: `examples/` provides 6 tfvars for MySQL/PostgreSQL HA clusters, connection proxy, cross-region DR, restore from backup, and monitoring.

## 12. Dependencies

- [huaweicloud/huaweicloud](https://registry.terraform.io/providers/huaweicloud/huaweicloud) provider `~> 1.94`
- Terraform `>= 1.5`

## 13. FAQ

- **Read replica limits**: constrained by region quota; check the RDS console quota if creation fails.
- **Proxy for PostgreSQL?**: The database proxy currently supports MySQL only; for PostgreSQL, disable `enable_proxy` or use an application-level pool (e.g., PgBouncer).
- **No VPC?**: The module creates a VPC/subnet/security group by default; to reuse an existing VPC, switch `vpc_id` to a data source (see docs/architecture.md §3).
- **Monitoring shows no data**: metric collection takes 5–10 minutes; refresh later, and ensure the dashboard dimension selects the current instance ID.

## 14. Contribution

Pull requests and issues are welcome. Please follow the existing code style and validate Terraform configurations (`terraform fmt` / `terraform validate`) before submitting.

## 15. License

This practice is licensed under **MIT No Attribution**. See [LICENSE](LICENSE).

## 16. Contact

- **Creator**: dgc-git
- **Maintainer**: dgc-git
- Feedback: GitHub Issues

## 17. Creator and Maintainers

| Role | Info |
|---|---|
| **Creator** | dgc-git |
| **Maintainer** | dgc-git |