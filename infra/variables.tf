# ============================================================================
# 变量定义
# ============================================================================

variable "region" {
  description = "华为云区域"
  type        = string
  default     = "cn-north-4"
}

variable "name" {
  description = "资源名称前缀（项目/集群名）"
  type        = string
  default     = "dat-poc"
}

variable "environment" {
  description = "环境标识（dev/test/prod）"
  type        = string
  default     = "dev"
}

variable "engine" {
  description = "数据库引擎：MySQL 或 PostgreSQL"
  type        = string
  default     = "MySQL"
  validation {
    condition     = contains(["MySQL", "PostgreSQL"], var.engine)
    error_message = "engine 只支持 MySQL 或 PostgreSQL。"
  }
}

variable "engine_version" {
  description = "数据库引擎版本（如 MySQL 8.0 / PostgreSQL 14）"
  type        = string
  default     = ""
}

variable "instance_flavor" {
  description = "主实例规格（flavor），如 rds.mysql.x1.large.2.ha"
  type        = string
  default     = ""
}

variable "read_replica_count" {
  description = "只读副本数量（默认 1，设置 0 可关闭）"
  type        = number
  default     = 1
}

variable "read_replica_flavor" {
  description = "只读副本规格，留空则与主实例一致"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "新建 VPC 的 CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "新建子网的 CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "db_password" {
  description = "数据库管理员密码（留空则由凭据管理服务生成并保存）"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_port" {
  description = "数据库端口（MySQL 默认 3306，PostgreSQL 默认 5432）"
  type        = number
  default     = 0
}

variable "volume_size" {
  description = "存储容量（GB）"
  type        = number
  default     = 100
}

variable "volume_type" {
  description = "存储类型：CLOUDSSD / ULTRAHIGH"
  type        = string
  default     = "CLOUDSSD"
}

variable "backup_retention_days" {
  description = "自动备份保留天数"
  type        = number
  default     = 7
}

variable "enable_proxy" {
  description = "是否创建连接代理（连接池复用，仅 MySQL 引擎支持）"
  type        = bool
  default     = false
}

variable "proxy_flavor" {
  description = "连接代理规格（如 2）"
  type        = string
  default     = "2"
}

variable "proxy_node_num" {
  description = "连接代理节点数"
  type        = number
  default     = 2
}

variable "enable_cross_region_backup" {
  description = "是否开启跨区域备份（容灾）"
  type        = bool
  default     = false
}

variable "destination_region" {
  description = "跨区域备份的目标区域"
  type        = string
  default     = "cn-south-1"
}

variable "enable_monitoring" {
  description = "是否创建监控看板与告警"
  type        = bool
  default     = true
}

variable "alarm_notify_email" {
  description = "告警通知邮箱（创建 SMN 订阅）"
  type        = string
  default     = ""
}

variable "restore_backup_id" {
  description = "从指定备份恢复时传入备份 ID（留空则新建实例）"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "自定义密钥 ID，留空则自动创建"
  type        = string
  default     = ""
}

variable "tags" {
  description = "资源标签"
  type        = map(string)
  default     = {}
}
variable "availability_zones" {
  description = "主实例可用区列表（如 [\"cn-north-4a\", \"cn-north-4b\"]，高可用跨可用区，留空由服务端选择）"
  type        = list(string)
  default     = []
}
