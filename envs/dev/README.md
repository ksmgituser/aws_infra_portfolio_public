# Root module - envs/dev

## What this env creates
Laravel + nginx on ECS Fargate を中心とした AWS インフラ一式。

| リソース | 内容 |
|---------|------|
| VPC | パブリック / プライベートサブネット（2AZ）、NAT Gateway |
| ECS Fargate | nginx + php-fpm の2コンテナ構成、CodeDeploy Blue/Green |
| RDS MariaDB | プライベートサブネット配置、db.t3.micro |
| ALB | HTTP→HTTPS リダイレクト、Blue/Green 対応リスナー（443/8080）|
| ACM | Route53 DNS 検証による自動発行 |
| Route53 | パブリックホストゾーン、ALB Alias レコード |
| ECR | app / nginx の2リポジトリ |
| VPC Endpoint | ECR / SSM / CloudWatch Logs（Interface）、S3（Gateway）|
| SSM Parameter Store | DB 接続情報・APP_KEY の保管 |
| S3 | ALB アクセスログ用バケット |
| EC2 Bastion | SSM Session Manager 経由のDB作業用 |
| IAM | ECS タスクロール / 実行ロール、Bastion 用ロール |

## File layout

| ファイル | 担当リソース |
|---------|------------|
| `provider.tf` | AWS プロバイダー / Terraform バックエンド設定 |
| `network.tf` | VPC モジュール呼び出し |
| `sg.tf` | 全 Security Group（ALB / ECS / RDS / Bastion / VPCE）+ クロスSGルール |
| `vpc_endpoint.tf` | VPC Endpoint モジュール呼び出し |
| `acm.tf` | ACM 証明書モジュール呼び出し |
| `dns.tf` | Route53 モジュール呼び出し |
| `s3.tf` | ALB ログ用 S3 バケットモジュール呼び出し |
| `alb.tf` | ALB モジュール呼び出し |
| `ecr.tf` | ECR モジュール呼び出し |
| `iam.tf` | IAM（ECS / Bastion）モジュール呼び出し |
| `ecs.tf` | ECS クラスター / サービス / タスク定義 / CodeDeploy |
| `rds.tf` | RDS MariaDB モジュール呼び出し |
| `ssm.tf` | SSM Parameter Store モジュール呼び出し |
| `ec2.tf` | Bastion EC2 モジュール呼び出し |
| `db_restore.tf` | DB リストア用 SSM Run Document（初回セットアップ補助）|
| `variables.tf` | 変数定義 |
| `outputs.tf` | 出力値定義 |

## Required variables (terraform.tfvars)

| 変数 | 説明 | 注意 |
|-----|------|------|
| `env` | 環境名（例: dev） | |
| `system` | システム名（例: portfolio） | |
| `department` | 部門名（例: infra） | |
| `domain` | Route53 で管理するサブドメイン | 外部レジストラへの NS 登録が別途必要 |
| `app_key` | Laravel の APP_KEY | `base64:...` 形式。アプリの `.env` から取得 |
| `allowed_cidr` | ALB への接続を許可する CIDR | 自宅 IP など。`0.0.0.0/0` にするとフルオープン |
| `org_prefix` | S3 バケット名のプレフィックス | グローバル一意性のため組織固有の値を使う |
| `bucket_suffix` | S3 バケット名のサフィックス | 初回作成時の日時を推奨。**変更すると新バケットが作られる** |

## Known constraints & gotchas

### ACM が完了するには NS レコード登録が必要
Route53 ホストゾーンを作成後、払い出された NS レコードを外部レジストラに登録しないと ACM の DNS 検証が完了せず `terraform apply` がタイムアウトする。

**推奨手順:**
1. `terraform apply -target=module.route53` で先にホストゾーンだけ作る
2. `terraform output` で NS レコードを確認し、外部レジストラに登録
3. DNS が反映したら残りを `terraform apply` で適用

### bucket_suffix は初回 apply 時に固定する
`bucket_suffix` を変えると S3 バケット名が変わり、ALB ログ設定が壊れる。
`terraform.tfvars` に値を書いた後は変更しないこと。

### RDS の SG ルールはモジュール外で管理
ECS SG → RDS SG のクロス参照は循環依存になるため、`sg.tf` で `aws_security_group_rule` として独立定義している。
RDS モジュールは `lifecycle { ignore_changes = [ingress] }` でドリフトを許容している。

### CodeDeploy コントローラーのため force-new-deployment は使えない
ECS サービスのデプロイコントローラーは `CODE_DEPLOY` のため、`aws ecs update-service --force-new-deployment` は効かない。
タスクを再起動するには stop-task するか、CodeDeploy でデプロイを実行すること。
