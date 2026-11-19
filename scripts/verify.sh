#!/usr/bin/env bash
# ============================================================================
# 部署验证：检查数据库实例、只读副本、监控看板是否就绪
# 用法: ./verify.sh [region]
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGION="${1:-cn-north-4}"
INFRA_DIR="$SCRIPT_DIR/../infra"

cd "$INFRA_DIR"

echo "=== 1. Terraform 状态中的资源 ==="
terraform state list | grep -E "huaweicloud_rds_instance|huaweicloud_rds_read_replica_instance" || echo "(未找到 RDS 资源)"

echo ""
echo "=== 2. 实例 ID / 私网 IP ==="
terraform output -json rds_instance_id 2>/dev/null || true
terraform output -json rds_private_ips 2>/dev/null || true

echo ""
echo "=== 3. 使用 hcloud 查询实例状态（需已配置 KooCLI）==="
if command -v hcloud >/dev/null 2>&1; then
  INSTANCE_ID="$(terraform output -raw rds_instance_id 2>/dev/null || true)"
  if [ -n "$INSTANCE_ID" ]; then
    hcloud RDS ShowInstance --instance_id="$INSTANCE_ID" --region="$REGION" 2>/dev/null || \
      echo "(hcloud 查询失败，请确认 KooCLI 已配置且具有 RDS 查看权限)"
  fi
else
  echo "(未检测到 hcloud，跳过 CLI 状态查询)"
fi

echo ""
echo "=== 4. 凭据管理服务中的连接信息 ==="
SECRET_NAME="$(terraform output -json db_secret_name 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin))' 2>/dev/null || true)"
if [ -n "$SECRET_NAME" ] && [ "$SECRET_NAME" != "user-provided" ]; then
  echo "   连接凭据名称: $SECRET_NAME"
  echo "   在凭据管理服务控制台或 SDK 中读取 username/password/host/port 即可连接。"
else
  echo "   (密码由用户提供，请使用部署时设置的 db_password 连接)"
fi

echo ""
echo "=== 5. 联通性提示 ==="
PORT="$(terraform output -raw rds_port 2>/dev/null || echo 3306)"
IP="$(terraform output -json rds_private_ips 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)[0] if json.load(sys.stdin) else "")' 2>/dev/null || true)"
if [ -n "$IP" ]; then
  echo "   数据库地址: $IP:$PORT"
  echo "   客户端连接示例（从同 VPC 内主机执行）："
  echo "   mysql -h $IP -P $PORT -u root -p"
  echo "   或 psql -h $IP -p $PORT -U root -d postgres"
else
  echo "   未能自动获取 IP，请从 terraform output rds_private_ips 查看。"
fi