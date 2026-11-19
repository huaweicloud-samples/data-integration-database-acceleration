# ============================================================================
# 输出
# ============================================================================

output "rds_instance_id" {
  description = "数据库实例 ID"
  value       = huaweicloud_rds_instance.this.id
}

output "rds_private_ips" {
  description = "数据库实例私网 IP"
  value       = huaweicloud_rds_instance.this.private_ips
}

output "rds_port" {
  description = "数据库端口"
  value       = local.db_port
}

output "rds_read_replica_ids" {
  description = "只读副本实例 ID 列表"
  value       = huaweicloud_rds_read_replica_instance.read[*].id
}

output "db_secret_name" {
  description = "数据库连接凭据名称（凭据管理服务）"
  value       = var.db_password == "" ? try(huaweicloud_csms_secret.db[0].name, "") : "user-provided"
  sensitive   = true
}

output "proxy_address" {
  description = "数据库代理访问地址（启用代理时）"
  value       = try(huaweicloud_rds_mysql_proxy.this[0].address, "")
}

output "monitoring_dashboard_id" {
  description = "监控仪表盘 ID（启用监控时）"
  value       = try(huaweicloud_ces_dashboard.db[0].id, "")
}

output "restored_instance_id" {
  description = "从备份恢复的新实例 ID（启用恢复时）"
  value       = try(huaweicloud_rds_instance.restored[0].id, "")
}