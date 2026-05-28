# ------------------------------------------------
# DB Restore via SSM Run Command
# RDS が再作成されたとき（address が変わったとき）に自動でリストアを実行する
# ------------------------------------------------
resource "null_resource" "db_restore" {
  triggers = {
    rds_address = module.rds_mariadb.address
  }

  depends_on = [
    module.rds_mariadb,
    module.bastion_ec2,
    module.ssm,
  ]

  provisioner "local-exec" {
    command = <<-EOT
      set -e

      INSTANCE_ID=$(aws ec2 describe-instances \
        --filters \
          "Name=tag:Name,Values=dev-portfolio-bastion-ec2" \
          "Name=instance-state-name,Values=running" \
        --query "Reservations[0].Instances[0].InstanceId" \
        --output text \
        --region ap-northeast-1)

      echo "Bastion instance: $INSTANCE_ID"

      # SSM エージェントが Online になるまで待つ（最大5分）
      echo "Waiting for SSM agent to be online..."
      for i in $(seq 1 30); do
        STATUS=$(aws ssm describe-instance-information \
          --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
          --query "InstanceInformationList[0].PingStatus" \
          --output text \
          --region ap-northeast-1 2>/dev/null || echo "None")
        if [ "$STATUS" = "Online" ]; then
          echo "SSM agent is online"
          break
        fi
        echo "  Attempt $i/30: status=$STATUS, retrying in 10s..."
        sleep 10
      done

      # SSM Run Command でリストア実行
      CMD_ID=$(aws ssm send-command \
        --instance-ids "$INSTANCE_ID" \
        --document-name "AWS-RunShellScript" \
        --comment "DB restore from S3" \
        --parameters 'commands=[
          "dnf install -y mariadb105 2>/dev/null || true",
          "aws s3 cp s3://com-infra-nikki-portfolio-artifact-bucket/ip_mgmt_app/dbdump/dev/init.sql /tmp/init.sql --region ap-northeast-1",
          "DB_HOST=$(aws ssm get-parameter --name /dev/portfolio/rds/mariadb/host --query Parameter.Value --output text --region ap-northeast-1)",
          "DB_USER=$(aws ssm get-parameter --name /dev/portfolio/rds/mariadb/username --query Parameter.Value --output text --region ap-northeast-1)",
          "DB_PASS=$(aws ssm get-parameter --name /dev/portfolio/rds/mariadb/password --with-decryption --query Parameter.Value --output text --region ap-northeast-1)",
          "DB_NAME=$(aws ssm get-parameter --name /dev/portfolio/rds/mariadb/database --query Parameter.Value --output text --region ap-northeast-1)",
          "mysql -h \"$DB_HOST\" -u \"$DB_USER\" -p\"$DB_PASS\" \"$DB_NAME\" < /tmp/init.sql",
          "echo DB_RESTORE_DONE"
        ]' \
        --region ap-northeast-1 \
        --query "Command.CommandId" \
        --output text)

      echo "SSM Command ID: $CMD_ID"

      # 完了待ち（最大10分）
      aws ssm wait command-executed \
        --command-id "$CMD_ID" \
        --instance-id "$INSTANCE_ID" \
        --region ap-northeast-1 \
        --cli-read-timeout 600

      # 結果確認
      RESULT=$(aws ssm get-command-invocation \
        --command-id "$CMD_ID" \
        --instance-id "$INSTANCE_ID" \
        --region ap-northeast-1 \
        --query "Status" \
        --output text)

      echo "DB restore status: $RESULT"

      if [ "$RESULT" != "Success" ]; then
        echo "DB restore failed!"
        exit 1
      fi
    EOT
  }
}
