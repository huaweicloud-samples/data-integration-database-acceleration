# ============================================================================
# 示例：MySQL 集群 + 跨区域容灾备份
# ============================================================================
# 对应场景：预置主集群并开启跨区域备份，将自动备份复制到目标区域。
# 注意：需先获取目标区域的项目 ID（华为云控制台 - 我的凭证）。
# 用法：
#   cd infra
#   terraform apply -var-file=../examples/mysql-cluster-global-db.tfvars
# ============================================================================

region            = "cn-north-4"
name              = "mysql-global-poc"
environment       = "dev"
engine            = "MySQL"
engine_version    = "8.0"
instance_flavor   = "rds.mysql.x1.large.2.ha"
read_replica_count = 1

vpc_cidr          = "10.0.0.0/16"
subnet_cidr       = "10.0.1.0/24"

volume_size       = 100

enable_cross_region_backup = true
destination_region         = "cn-south-1"
destination_project_id     = "<DESTINATION_PROJECT_ID>"

enable_monitoring = true
alarm_notify_email = ""

tags = {
  Environment = "dev"
  Project     = "database-acceleration"
}