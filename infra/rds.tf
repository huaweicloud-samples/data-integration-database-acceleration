# ============================================================================
# 数据库集群：主实例（高可用）+ 只读副本 + 参数组
# ============================================================================

# 数据库参数组（对应引擎调优参数）
resource "huaweicloud_rds_parametergroup" "this" {
  name        = "${var.name}-param-${var.environment}"
  description = "Database parameter group - ${var.name} ${var.environment}"

  datastore {
    type    = local.engine_lower
    version = var.engine_version != "" ? var.engine_version : (var.engine == "PostgreSQL" ? "14" : "8.0")
  }

  # MySQL 通用调优参数
  values = var.engine == "MySQL" ? {
    slow_query_log             = "ON"
    long_query_time            = "10"
    innodb_print_all_deadlocks = "ON"
    } : {
    # PostgreSQL 常见调优参数
    log_statement                       = "ddl"
    log_min_duration_statement          = "5000"
    idle_in_transaction_session_timeout = "7200000"
    statement_timeout                   = "7200000"
  }
}

locals {
  # 可用区：显式指定优先，否则按区域默认（a 可用区）
  az_list      = length(var.availability_zones) > 0 ? var.availability_zones : ["${var.region}a"]
  az_primary   = local.az_list[0]
  engine_lower = lower(var.engine)

  rds_flavor = var.instance_flavor != "" ? var.instance_flavor : (
    var.engine == "PostgreSQL"
    ? "rds.pg.n1.large.2"
    : "rds.mysql.n1.large.2"
  )
  rds_replica_flavor = var.read_replica_flavor != "" ? var.read_replica_flavor : local.rds_flavor
}

# 主实例：高可用（主备）
resource "huaweicloud_rds_instance" "this" {
  name              = "${var.name}-db-${var.environment}"
  flavor            = local.rds_flavor
  vpc_id            = huaweicloud_vpc.this.id
  subnet_id         = huaweicloud_vpc_subnet.this.id
  security_group_id = huaweicloud_networking_secgroup.db.id
  availability_zone = local.az_list
  param_group_id    = huaweicloud_rds_parametergroup.this.id

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

  backup_strategy {
    start_time = "02:00-03:00"
    keep_days  = var.backup_retention_days
  }

  tags = merge(var.tags, {
    Name        = "${var.name}-db-${var.environment}"
    Environment = var.environment
  })
}

# 只读副本（对应集群 reader 节点）
resource "huaweicloud_rds_read_replica_instance" "read" {
  count = var.read_replica_count > 0 ? var.read_replica_count : 0

  name                = "${var.name}-db-${var.environment}-ro-${count.index + 1}"
  flavor              = local.rds_replica_flavor
  primary_instance_id = huaweicloud_rds_instance.this.id
  availability_zone   = local.az_primary

  volume {
    type = var.volume_type
    size = var.volume_size
  }

  tags = merge(var.tags, {
    Name        = "${var.name}-db-${var.environment}-ro-${count.index + 1}"
    Environment = var.environment
  })
}