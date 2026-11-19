# ============================================================================
# 示例：MySQL 集群 + 连接代理（连接池复用）
# ============================================================================
# 对应场景：在预置集群之上开启数据库代理，复用连接、提升可靠性。
# 用法：
#   cd infra
#   terraform apply -var-file=../examples/mysql-dbproxy.tfvars
# ============================================================================

region            = "cn-north-4"
name              = "mysql-proxy-poc"
environment       = "dev"
engine            = "MySQL"
engine_version    = "8.0"
instance_flavor   = "rds.mysql.x1.large.2.ha"
read_replica_count = 0

vpc_cidr          = "10.0.0.0/16"
subnet_cidr       = "10.0.1.0/24"

volume_size       = 100

enable_proxy      = true
proxy_flavor      = "2"
proxy_node_num    = 2

enable_monitoring = true
alarm_notify_email = ""

tags = {
  Environment = "dev"
  Project     = "database-acceleration"
}