# ============================================================================
# 示例：MySQL 集群 + 监控（监控看板 + 告警通知）
# ============================================================================
# 对应场景：预置 MySQL 高可用集群，并随集群创建 CES 监控看板与告警配置。
# 注意：监控看板默认绑定本示例新建的实例；若需监控既有实例，
#       请将 infra/monitoring.tf 中 huaweicloud_rds_instance.this.id
#       替换为既有实例 ID（数据源方式）。
# 用法：
#   cd infra
#   terraform apply -var-file=../examples/mysql-monitoring.tfvars
# ============================================================================

region            = "cn-north-4"
name              = "mysql-monitoring-poc"
environment       = "dev"
engine            = "MySQL"
engine_version    = "8.0"
instance_flavor   = "rds.mysql.x1.large.2.ha"
read_replica_count = 1

vpc_cidr          = "10.0.0.0/16"
subnet_cidr       = "10.0.1.0/24"

volume_size       = 100

enable_monitoring = true
alarm_notify_email = "<YOUR_EMAIL>@example.com"

tags = {
  Environment = "dev"
  Project     = "database-acceleration"
}