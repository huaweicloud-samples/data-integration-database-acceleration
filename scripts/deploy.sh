#!/usr/bin/env bash
# ============================================================================
# 一键部署：初始化并应用 Terraform 配置
# 用法:
#   ./deploy.sh <示例 tfvars 文件>
# 示例:
#   ./deploy.sh ../examples/mysql-cluster-existing-vpc.tfvars
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/../infra"
TFVARS="${1:-}"

cd "$INFRA_DIR"

echo "[1/3] 检查环境变量（华为云 Access Key / Secret Key）"
: "${HW_ACCESS_KEY:?请先 export HW_ACCESS_KEY=<你的 Access Key>}"
: "${HW_SECRET_KEY:?请先 export HW_SECRET_KEY=<你的 Secret Key>}"
echo "      已检测到华为云凭据。"

echo "[2/3] terraform init"
if [ ! -d ".terraform" ]; then
  terraform init -input=false
else
  echo "      .terraform 已存在，跳过 init"
fi

if [ -n "$TFVARS" ]; then
  echo "[3/3] terraform apply (var-file=$TFVARS)"
  terraform apply -auto-approve -var-file="$TFVARS"
else
  echo "[3/3] terraform apply"
  terraform apply -auto-approve
fi

echo ""
echo "部署完成。输出摘要："
terraform output
echo ""
echo "下一步：运行 ./verify.sh 验证数据库连接。"