# ============================================================================
# 监控与告警：CES 仪表盘 + 告警规则 + SMN 通知
# ============================================================================

# 告警通知：SMN 主题与订阅
resource "huaweicloud_smn_topic" "db_alarm" {
  count = var.alarm_notify_email != "" ? 1 : 0

  name         = "${var.name}-db-alarm-${var.environment}"
  display_name = "Database alarm notifications - ${var.name}"
}

resource "huaweicloud_smn_subscription" "db_alarm_email" {
  count = var.alarm_notify_email != "" ? 1 : 0

  topic_urn = huaweicloud_smn_topic.db_alarm[0].topic_urn
  protocol  = "email"
  endpoint  = var.alarm_notify_email
}

locals {
  alarm_topic_urn = var.alarm_notify_email != "" ? huaweicloud_smn_topic.db_alarm[0].topic_urn : ""
}

# 说明：告警规则在云监控控制台创建（见部署指导书 §6.3）
# （Terraform 资源对 SYS.RDS 命名空间的指标白名单存在兼容问题，实测 ces.0014；
#   看板与 SMN 通知仍由 Terraform 管理）

# 监控仪表盘
resource "huaweicloud_ces_dashboard" "db" {
  count = var.enable_monitoring ? 1 : 0

  name           = "${var.name}-dashboard-${var.environment}"
  row_widget_num = 3
}

resource "huaweicloud_ces_dashboard_widget" "cpu" {
  count = var.enable_monitoring ? 1 : 0

  dashboard_id        = huaweicloud_ces_dashboard.db[0].id
  title               = "CPU Utilization"
  view                = "line"
  metric_display_mode = "single"

  metrics {
    metric_name = "rds001_cpu_util"
    namespace   = "SYS.RDS"
    alias       = ["max", "avg"]

    dimensions {
      filter_type = "specific_instances"
      name        = "rds_cluster_id"
      values      = [huaweicloud_rds_instance.this.id]
    }
  }

  location {
    top    = 0
    left   = 0
    width  = 6
    height = 4
  }

  properties {
    top_n = 5
  }
}

resource "huaweicloud_ces_dashboard_widget" "storage" {
  count = var.enable_monitoring ? 1 : 0

  dashboard_id        = huaweicloud_ces_dashboard.db[0].id
  title               = "Volume Usage"
  view                = "line"
  metric_display_mode = "single"

  metrics {
    metric_name = "rds039_disk_util"
    namespace   = "SYS.RDS"
    alias       = ["max", "avg"]

    dimensions {
      filter_type = "specific_instances"
      name        = "rds_cluster_id"
      values      = [huaweicloud_rds_instance.this.id]
    }
  }

  location {
    top    = 0
    left   = 6
    width  = 6
    height = 4
  }

  properties {
    top_n = 5
  }
}