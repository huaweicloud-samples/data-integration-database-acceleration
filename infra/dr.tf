# ============================================================================
# 跨区域容灾：跨区域备份策略
# ============================================================================
# 对应高可用容灾需求：将数据库备份复制到另一区域，作为区域级故障时的恢复手段。

variable "destination_project_id" {
  description = "目标区域的项目 ID（跨区域备份必需）"
  type        = string
  default     = ""
}

resource "huaweicloud_rds_cross_region_backup_strategy" "this" {
  count = var.enable_cross_region_backup ? 1 : 0

  instance_id            = huaweicloud_rds_instance.this.id
  backup_type            = "auto"
  destination_region     = var.destination_region
  destination_project_id = var.destination_project_id
  keep_days              = var.backup_retention_days
}