# ============================================================================
# 密钥与凭据：KMS 加密 + 凭据管理（连接串）
# ============================================================================

resource "huaweicloud_kms_key" "this" {
  count = var.kms_key_id == "" ? 1 : 0

  key_alias    = "${var.name}-key-${var.environment}"
  key_usage    = "ENCRYPT_DECRYPT"
  pending_days = "7"

  tags = merge(var.tags, {
    Name        = "${var.name}-key-${var.environment}"
    Environment = var.environment
  })
}

locals {
  db_encryption_key_id = var.kms_key_id != "" ? var.kms_key_id : try(huaweicloud_kms_key.this[0].id, "")
}

# 数据库连接凭据：生成随机密码并写入凭据管理服务
resource "random_password" "db_master" {
  count = var.db_password == "" ? 1 : 0

  length      = 20
  special     = true
  min_special = 2
  # 华为云 RDS 密码策略要求：大写/小写/数字/特殊字符至少三类
  override_special = "!@#$%^&*()-_=+"
}

locals {
  db_user     = "root"
  db_password = var.db_password != "" ? var.db_password : try(random_password.db_master[0].result, "")
  db_name     = replace(var.name, "-", "_")
}

resource "huaweicloud_csms_secret" "db" {
  count = var.db_password == "" ? 1 : 0

  name        = "${var.name}-secret-${var.environment}"
  description = "Database connection secret - ${var.name} ${var.environment}"
  secret_text = jsonencode({
    username      = local.db_user
    password      = local.db_password
    database_name = local.db_name
    host          = try(huaweicloud_rds_instance.this.private_ips[0], "")
    port          = local.db_port
    engine        = var.engine
  })
  secret_type = "COMMON"

  tags = merge(var.tags, {
    Name        = "${var.name}-secret-${var.environment}"
    Environment = var.environment
  })
}