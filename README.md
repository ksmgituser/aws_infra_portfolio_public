# infra-portfolio

## モジュール構成

| 分類 | モジュール | 意図 |
|-----|----------|------|
| common | naming | 全モジュール共通の命名・タグ生成 |
| network | vpc | VPC / サブネット / ルートテーブル / NAT Gateway |
| network | security_group/alb | ALB 用 SG |
| network | security_group/ecs | ECS Fargate 用 SG |
| network | security_group/rds | RDS 用 SG |
| network | security_group/bastion | Bastion 用 SG（SSM 前提・inbound なし）|
| network | security_group/vpce | VPC Endpoint 用 SG |
| network | vpc_endpoint | Interface / Gateway 型 VPC Endpoint |
| elb | alb | ALB / ターゲットグループ / リスナー（Blue/Green 対応）|
| container | ecr | ECR リポジトリ / ライフサイクルポリシー |
| container | ecs | ECS クラスター / サービス / タスク定義 / CodeDeploy |
| database | rds/mariadb | RDS MariaDB インスタンス / サブネットグループ |
| compute | ec2/bastion | Bastion EC2（SSM Session Manager 経由）|
| identity | iam/ecs | ECS タスクロール / 実行ロール |
| identity | iam/ec2/bastion | Bastion IAM ロール / インスタンスプロファイル |
| dns | route53 | ホストゾーン / ALB Alias レコード |
| security | acm | ACM 証明書（DNS 検証）|
| storage | s3/alb_logs | ALB アクセスログ用 S3 バケット |
| management | ssm | SSM Parameter Store パラメータ |

```
infra_portfolio/
├── docs/                          # 公開用ドキュメント（git管理・センシティブ情報は伏字）
│   ├── 01_requirements.md
│   ├── 02_basic-design.md
│   ├── 04_operations.md
│   ├── 05_test-spec.md
│   └── diagrams/
│       └── 02_AWS_Arch.png
├── envs/
│   └── dev/
│       ├── provider.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       ├── outputs.tf
│       ├── network.tf
│       ├── sg.tf
│       ├── vpc_endpoint.tf
│       ├── acm.tf
│       ├── dns.tf
│       ├── s3.tf
│       ├── alb.tf
│       ├── ecr.tf
│       ├── iam.tf
│       ├── ecs.tf
│       ├── rds.tf
│       ├── ssm.tf
│       ├── ec2.tf
│       ├── db_restore.tf
│       └── README.md
│
└── modules/
    ├── common/
    │   └── naming/
    ├── network/
    │   ├── vpc/
    │   ├── vpc_endpoint/
    │   └── security_group/
    │       ├── alb/
    │       ├── ecs/
    │       ├── rds/
    │       ├── bastion/
    │       └── vpce/
    ├── elb/
    │   └── alb/
    ├── container/
    │   ├── ecr/
    │   └── ecs/
    ├── database/
    │   └── rds/
    │       └── mariadb/
    ├── compute/
    │   └── ec2/
    │       └── bastion/
    ├── identity/
    │   └── iam/
    │       ├── ecs/
    │       └── ec2/
    │           └── bastion/
    ├── dns/
    │   └── route53/
    ├── security/
    │   └── acm/
    ├── storage/
    │   └── s3/
    │       └── alb_logs/
    └── management/
        └── ssm/
```

---

## 初回セットアップ手順

### 1. terraform init & apply

```bash
cd envs/dev
terraform init
terraform apply
```

### 2. ECRにイメージをpush

```bash
cd ~/projects/2026/ip_mgmt_app

# ECRログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com

# appイメージ
docker build -f infra/php/Dockerfile.aws -t dev-portfolio-container-ecr-app .
docker tag dev-portfolio-container-ecr-app:latest <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/dev-portfolio-container-ecr-app:latest
docker push <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/dev-portfolio-container-ecr-app:latest

# nginxイメージ
docker build -f infra/nginx/Dockerfile.aws -t dev-portfolio-container-ecr-nginx .
docker tag dev-portfolio-container-ecr-nginx:latest <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/dev-portfolio-container-ecr-nginx:latest
docker push <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/dev-portfolio-container-ecr-nginx:latest
```

### 3. DBダンプをリストア（bastionホスト経由）

```bash
# bastionに接続
aws ssm start-session --target <bastion-instance-id>

# S3からダンプ取得
aws s3 cp s3://com-infra-nikki-portfolio-artifact-bucket/ip_mgmt_app/dbdump/dev/init.sql /tmp/init.sql --region ap-northeast-1

# SSMから接続情報を取得
DB_HOST=$(aws ssm get-parameter --name "/dev/portfolio/rds/mariadb/host" --query "Parameter.Value" --output text)
DB_USER=$(aws ssm get-parameter --name "/dev/portfolio/rds/mariadb/username" --query "Parameter.Value" --output text)
DB_PASS=$(aws ssm get-parameter --name "/dev/portfolio/rds/mariadb/password" --with-decryption --query "Parameter.Value" --output text)
DB_NAME=$(aws ssm get-parameter --name "/dev/portfolio/rds/mariadb/database" --query "Parameter.Value" --output text)

# リストア
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME < /tmp/init.sql
```

### 4. CodeDeployでECSにデプロイ

```bash
# 最新タスク定義のrevision番号を確認
aws ecs describe-task-definition \
  --task-definition dev-portfolio-container-ecs-task \
  --query "taskDefinition.taskDefinitionArn" \
  --output text

# appspec.jsonを作成（Nを最新revisionに変える）
python3 -c "
import json
content = {
  'version': 1,
  'Resources': [{
    'TargetService': {
      'Type': 'AWS::ECS::Service',
      'Properties': {
        'TaskDefinition': 'arn:aws:ecs:ap-northeast-1:<account-id>:task-definition/dev-portfolio-container-ecs-task:N',
        'LoadBalancerInfo': {'ContainerName': 'nginx', 'ContainerPort': 80}
      }
    }
  }]
}
open('/tmp/appspec.json', 'w').write(json.dumps(content))
print('OK')
"

# デプロイ実行
aws deploy create-deployment \
  --application-name dev-portfolio-container-ecs-codedeploy \
  --deployment-group-name dev-portfolio-container-ecs-deploy-group \
  --revision "{\"revisionType\":\"AppSpecContent\",\"appSpecContent\":{\"content\":$(python3 -c 'import json; print(json.dumps(open("/tmp/appspec.json").read()))')}}" \
  --profile portfolio-dev

# 進捗確認
aws deploy get-deployment \
  --deployment-id <deployment-id> \
  --query "deploymentInfo.{status:status,overview:deploymentOverview}" \
  --output table \
  --profile portfolio-dev
```

---

## 運用オペレーション

### ECS Execでコンテナに入る

```bash
TASK_ID=$(aws ecs list-tasks --cluster dev-portfolio-container-ecs-cluster \
  --query "taskArns[0]" --output text | awk -F/ '{print $NF}')

aws ecs execute-command \
  --cluster dev-portfolio-container-ecs-cluster \
  --task $TASK_ID \
  --container php-fpm \
  --interactive \
  --command "bash"
```

### Laravelエラーログ確認

```bash
# ECS Exec経由
aws ecs execute-command \
  --cluster dev-portfolio-container-ecs-cluster \
  --task $TASK_ID \
  --container php-fpm \
  --interactive \
  --command "sh -c 'grep -a \"production.ERROR\" /data/storage/logs/laravel.log | tail -20'"

# CloudWatch経由
aws logs filter-log-events \
  --log-group-name /ecs/dev-portfolio-php-fpm \
  --filter-pattern "ERROR" \
  --query "events[-10:].message" \
  --output text
```

### ECSタスクの再起動

※ CODE_DEPLOYコントローラーのためforce-new-deploymentは使えない

```bash
for task in $(aws ecs list-tasks --cluster dev-portfolio-container-ecs-cluster \
  --query "taskArns[]" --output text); do
  aws ecs stop-task --cluster dev-portfolio-container-ecs-cluster --task $task
done
```

### RDS疎通確認（コンテナ内から）

```bash
aws ecs execute-command \
  --cluster dev-portfolio-container-ecs-cluster \
  --task $TASK_ID \
  --container php-fpm \
  --interactive \
  --command "sh -c 'timeout 5 bash -c \"echo > /dev/tcp/<rds-endpoint>/3306\" && echo OK || echo FAILED'"
```

---

## Terraformバックエンド

- S3バケット: `com-infra-nikki-portfolio-artifact-bucket`
- キー: `tfstate/dev/terraform.tfstate`
- DynamoDB（ロック）: `portfolio-tfstate-lock`
- 環境ごとのkey:
  - dev: `tfstate/dev/terraform.tfstate`
  - stg: `tfstate/stg/terraform.tfstate`
  - prod: `tfstate/prod/terraform.tfstate`

