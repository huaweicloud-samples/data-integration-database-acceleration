# ============================================================================
# 连接代理：RDS 数据库代理（连接池复用，提升连接可靠性）
# ============================================================================
# 说明：华为云 RDS 提供数据库代理服务（连接池复用 + 读写分离）。
#       仅 MySQL 引擎支持代理；PostgreSQL 引擎请直接使用只读副本或应用层连接池。

resource "huaweicloud_rds_mysql_proxy" "this" {
  count = var.enable_proxy && var.engine == "MySQL" ? 1 : 0

  instance_id = huaweicloud_rds_instance.this.id
  flavor      = var.proxy_flavor
  node_num    = var.proxy_node_num

  proxy_name = "${var.name}-proxy-${var.environment}"

  subnet_id = huaweicloud_vpc_subnet.this.id
}