# ============================================================================
# 示例：MySQL 高可用集群（现有 VPC 模式，含只读副本）
# ============================================================================
# 对应场景：在目标区域内预置一个 MySQL 高可用集群（1 主 + 1 只读）。
# 用法：
#   cd infra
#   terraform plan   -var-file=../examples/mysql-cluster-existing-vpc.tfvars
#   terraform apply  -var-file=../examples/mysql-cluster-existing-vpc.tfvars
# ============================================================================

region            = "cn-north-4"
name              = "mysql-cluster-poc"
environment       = "dev"
engine            = "MySQL"
engine_version    = "8.0"
instance_flavor   = "rds.mysql.n1.large.2"
read_replica_count = 1
read_replica_flavor = "rds.mysql.x1.large.2.rr"

vpc_cidr          = "10.0.0.0/16"
subnet_cidr       = "10.0.1.0/24"

# 数据库密码：留空自动生成并存入凭据管理服务
# db_password     = "ChangeMe123!"

volume_size       = 100
volume_type       = "CLOUDSSD"
backup_retention_days = 7

enable_monitoring = true
alarm_notify_email = ""

tags = {
  Environment = "dev"
  Project     = "database-acceleration"
}