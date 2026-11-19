# ============================================================================
# 网络资源：VPC / 子网 / 安全组
# ============================================================================

resource "huaweicloud_vpc" "this" {
  name = "${var.name}-vpc-${var.environment}"
  cidr = var.vpc_cidr

  tags = merge(var.tags, {
    Name        = "${var.name}-vpc-${var.environment}"
    Environment = var.environment
  })
}

resource "huaweicloud_vpc_subnet" "this" {
  name       = "${var.name}-subnet-${var.environment}"
  vpc_id     = huaweicloud_vpc.this.id
  cidr       = var.subnet_cidr
  gateway_ip = cidrhost(var.subnet_cidr, 1)

  tags = merge(var.tags, {
    Name        = "${var.name}-subnet-${var.environment}"
    Environment = var.environment
  })
}

# 数据库安全组：仅允许私有网段与应用安全组访问数据库端口
resource "huaweicloud_networking_secgroup" "db" {
  name        = "${var.name}-db-sg-${var.environment}"
  description = "Database security group - ${var.name} ${var.environment}"

  tags = merge(var.tags, {
    Name        = "${var.name}-db-sg-${var.environment}"
    Environment = var.environment
  })
}

locals {
  # 端口按引擎选择：MySQL 3306 / PostgreSQL 5432
  db_port = var.db_port != 0 ? var.db_port : (var.engine == "PostgreSQL" ? 5432 : 3306)
}

resource "huaweicloud_networking_secgroup_rule" "db_ingress_vpc" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = local.db_port
  port_range_max    = local.db_port
  remote_ip_prefix  = var.vpc_cidr
  security_group_id = huaweicloud_networking_secgroup.db.id
}

resource "huaweicloud_networking_secgroup_rule" "db_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = local.db_port
  port_range_max    = local.db_port
  remote_ip_prefix  = var.vpc_cidr
  security_group_id = huaweicloud_networking_secgroup.db.id
}