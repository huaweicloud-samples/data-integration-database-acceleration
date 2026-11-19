# ============================================================================
# 示例：MySQL 集群 + 从备份恢复
# ============================================================================
# 对应场景：先从已有实例创建手动备份，再将恢复的新实例部署出来。
# 注意：restore_backup_id 需要先对已有实例执行手动备份后填入实际备份 ID。
# 用法：
#   1) 先 apply 基础集群（mysql-cluster-existing-vpc.tfvars）
#   2) 在控制台对实例创建手动备份，记下备份 ID
#   3) terraform apply -var-file=../examples/mysql-cluster-latest-snapshot.tfvars
# ============================================================================

region            = "cn-north-4"
name              = "mysql-restore-poc"
environment       = "dev"
engine            = "MySQL"
engine_version    = "8.0"
instance_flavor   = "rds.mysql.x1.large.2.ha"
read_replica_count = 0

vpc_cidr          = "10.0.0.0/16"
subnet_cidr       = "10.0.1.0/24"

volume_size       = 100

# 从备份恢复：填写要恢复的实例备份 ID
enable_manual_backup = false
restore_backup_id    = "<BACKUP_ID>"

enable_monitoring = true
alarm_notify_email = ""

tags = {
  Environment = "dev"
  Project     = "database-acceleration"
}