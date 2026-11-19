# ============================================================================
# 手动备份（快照）与从备份恢复
# ============================================================================

resource "huaweicloud_rds_backup" "manual" {
  count = var.enable_manual_backup ? 1 : 0

  instance_id = huaweicloud_rds_instance.this.id
  name        = "${var.name}-manual-backup-${var.environment}"
  description = "Manual database backup - ${var.name} ${var.environment}"
}

variable "enable_manual_backup" {
  description = "是否创建手动备份"
  type        = bool
  default     = false
}

# 新建实例：从指定备份恢复到新实例
resource "huaweicloud_rds_instance" "restored" {
  count = var.restore_backup_id != "" ? 1 : 0

  name              = "${var.name}-db-${var.environment}-restored"
  flavor            = local.rds_flavor
  vpc_id            = huaweicloud_vpc.this.id
  subnet_id         = huaweicloud_vpc_subnet.this.id
  security_group_id = huaweicloud_networking_secgroup.db.id
  availability_zone = local.az_list

  restore {
    backup_id   = var.restore_backup_id
    instance_id = huaweicloud_rds_instance.this.id
  }

  db {
    type     = local.engine_lower
    version  = var.engine_version != "" ? var.engine_version : (var.engine == "PostgreSQL" ? "14" : "8.0")
    password = local.db_password
    port     = local.db_port
  }

  volume {
    type               = var.volume_type
    size               = var.volume_size
    disk_encryption_id = local.db_encryption_key_id
  }

  tags = merge(var.tags, {
    Name        = "${var.name}-db-${var.environment}-restored"
    Environment = var.environment
  })
}