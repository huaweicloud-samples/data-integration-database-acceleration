# ============================================================================
# 示例：PostgreSQL 集群（含只读副本）
# ============================================================================
# 对应场景：预置 PostgreSQL 高可用集群（1 主 + 1 只读）。
# 用法：
#   cd infra
#   terraform apply -var-file=../examples/postgres-cluster-existing-vpc.tfvars
# ============================================================================

region            = "cn-north-4"
name              = "postgres-cluster-poc"
environment       = "dev"
engine            = "PostgreSQL"
engine_version    = "14"
instance_flavor   = "rds.pg.x1.large.2.ha"
read_replica_count = 1
read_replica_flavor = "rds.pg.x1.large.2"

vpc_cidr          = "10.0.0.0/16"
subnet_cidr       = "10.0.1.0/24"

volume_size       = 100
volume_type       = "CLOUDSSD"
backup_retention_days = 7

enable_monitoring = true
alarm_notify_email = ""

tags = {
  Environment = "dev"
  Project     = "database-acceleration"
}