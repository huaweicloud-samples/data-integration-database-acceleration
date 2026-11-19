# ============================================================================
# 数据库集群自动化部署套件 - Terraform 配置
# ============================================================================
# 本套件以 IaC 方式一键完成托管数据库集群的初始化、预置与持续运维：
#   - 高可用集群（主备 + 只读副本）
#   - 连接代理（连接池复用）
#   - 监控看板与告警
#   - 跨区域容灾备份
#   - 从备份恢复
# ============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "~> 1.94"
    }
  }
}

provider "huaweicloud" {
  region = var.region
  # 在华为云「我的凭证」页面获取 Access Key，并填入部署脚本或环境变量
  # export HW_ACCESS_KEY="your-access-key"
  # export HW_SECRET_KEY="your-secret-key"
}