# 運用設計書 <!-- omit from toc -->

# 目次 <!-- omit from toc -->
- [1. CI/CD設計](#1-cicd設計)
  - [1.1. 概要](#11-概要)
  - [1.2. GitHub Actions設計（infraリポジトリ）](#12-github-actions設計infraリポジトリ)
  - [1.3. GitHub Actions設計（appリポジトリ）](#13-github-actions設計appリポジトリ)
  - [1.4. Blue/Greenデプロイ設計（CodeDeploy）](#14-bluegreenデプロイ設計codedeploy)
  - [1.5. デプロイロールバック戦略](#15-デプロイロールバック戦略)
  - [1.6. GitHub Actions認証方式](#16-github-actions認証方式)
- [2. 監視・ログ設計](#2-監視ログ設計)
  - [2.1. 概要](#21-概要)
  - [2.2. CloudWatch Logs設計](#22-cloudwatch-logs設計)
  - [2.3. ALBアクセスログ設計](#23-albアクセスログ設計)
  - [2.4. アラート設計](#24-アラート設計)
- [3. バックアップ・リストア設計](#3-バックアップリストア設計)
  - [3.1. 概要](#31-概要)
  - [3.2. RDSバックアップ設計](#32-rdsバックアップ設計)
  - [3.3. リストア手順](#33-リストア手順)
- [4. コスト管理設計](#4-コスト管理設計)
  - [4.1. 概要](#41-概要)
  - [4.2. AWS Budgets設計](#42-aws-budgets設計)
  - [4.3. コスト最適化方針](#43-コスト最適化方針)
- [5. 障害対応設計](#5-障害対応設計)
  - [5.1. 概要](#51-概要)
  - [5.2. 障害検知フロー](#52-障害検知フロー)
  - [5.3. ECSタスク障害時の対応](#53-ecsタスク障害時の対応)
  - [5.4. RDSフェールオーバー対応](#54-rdsフェールオーバー対応)
- [6. セキュリティ運用設計](#6-セキュリティ運用設計)
  - [6.1. IAM運用方針](#61-iam運用方針)
  - [6.2. CloudTrail・AWS Config運用](#62-cloudtrailaws-config運用)
- [7. 運用Runbook](#7-運用runbook)
  - [7.1. 概要](#71-概要)
- [8. SLO（サービスレベル目標）](#8-sloサービスレベル目標)
  - [8.1. 可用性目標](#81-可用性目標)



# 1. CI/CD設計

## 1.1. 概要

- 本システムでは GitHub Actions を利用して CI/CD を実現する。
- インフラ構成とアプリケーションは以下の2つのリポジトリで管理する。

| リポジトリ             | 役割                         |
| ----------------- | -------------------------- |
| `portfolio-infra` | TerraformによるAWSインフラ管理      |
| `portfolio-app`   | アプリケーションコードおよびDockerイメージ管理 |


### CI/CDアーキテクチャ
#### インフラCI/CD
```
Developer
   ↓
GitHub (portfolio-infra)
   ↓
Pull Request
   ↓
GitHub Actions (terraform fmt / validate / plan)
   ↓
main merge
   ↓
GitHub Actions (terraform apply)
   ↓
AWS Infrastructure 更新
```

#### アプリケーションCI/CD
```
Developer
   ↓
GitHub (portfolio-app)
   ↓
Pull Request
   ↓
GitHub Actions (docker build / test)
   ↓
main merge
   ↓
Docker build
   ↓
ECR push
   ↓
CodeDeploy
   ↓
ECS Blue/Green Deployment
```

### ブランチ戦略

| ブランチ | 用途 | 直push | 備考 |
| --- | --- | --- | --- |
| `main` | 本番環境反映ブランチ | 禁止 | PR経由のmergeのみ許可 |
| `feature/*` | 機能開発・修正用 | 許可 | 作業完了後mainへPR |
| `docs/*` | ドキュメント修正用 | 許可 | 作業完了後mainへPR・CI/CDはスキップ |

### Branch Protection Rules（mainブランチ）

| 設定項目 | 値 | 備考 |
| --- | --- | --- |
| 直pushの禁止 | 有効 | feature/*ブランチからのPR経由のみ許可 |
| force pushの禁止 | 有効 | git historyの改ざんを防止 |
| PRのapprove必須 | 1件以上 | 一人開発のため自己approveで運用 |
| CIの成功必須 | 有効 | GitHub Actionsのワークフロー成功後のみmerge可能 |

### 開発フロー
```
① ローカルで作業ブランチを作成
   git checkout -b feature/xxx

② ローカルで開発・commit
   git add .
   git commit -m "feat: xxx"

③ GitHubへpush
   git push origin feature/xxx

④ GitHubでPRを作成（feature/xxx → main）

⑤ CI実行・成功確認
   └─ GitHub Actionsが自動実行
        portfolio-infra → terraform fmt / validate / tflint / plan
        portfolio-app   → docker build / lint / test

⑥ レビュー・approve
   └─ CI成功後にapprove可能（Branch Protection Rulesで制御）
   └─ 一人開発のため自己approveで運用

⑦ mainブランチへmerge
   └─ mergeをトリガーにGitHub Actionsが実行
        portfolio-infra → Terraform apply
        portfolio-app   → dockerビルド → ECR push → ECSデプロイ

⑧ 作業ブランチを削除
   git branch -d feature/xxx
```

### コミットメッセージ規約

#### 基本方針
Conventional Commitsの規約に準拠する。

#### フォーマット
```
<type>: <subject>

[body]
```

#### typeの種類

| type | 用途 | 例 |
| --- | --- | --- |
| `feat` | 新機能追加 | `feat: ECS Auto Scalingの設定を追加` |
| `fix` | バグ修正 | `fix: RDSのセキュリティグループ設定を修正` |
| `docs` | ドキュメントのみの変更 | `docs: 運用設計書にブランチ戦略を追記` |
| `chore` | ビルド・設定ファイル等の変更 | `chore: Terraformのバージョンを更新` |
| `refactor` | リファクタリング | `refactor: VPCモジュールを整理` |
| `test` | テストの追加・修正 | `test: フェールオーバー試験の手順を追加` |

#### ルール
- subjectは50文字以内
- 日本語・英語どちらでも可
- bodyは任意（変更の背景・理由を書く場合に使用）

#### 具体例

**subjectのみ（シンプルな変更）：**
```
feat: VPCエンドポイントにssmmessagesを追加
fix: nginxコンテナのヘルスチェックパスを修正
docs: 基本設計書のサブネット設計を実態に合わせて修正
chore: ECRのライフサイクルポリシーを10世代から5世代に変更
refactor: ネットワークモジュールをVPC・サブネット・SGに分割
```

**bodyあり（背景・理由を残したい変更）：**
```
feat: RDSのバックアップ保持期間を7日から1日に変更

コスト削減のため最小値（1日）に設定する。
本番運用時は要件に応じて再設定すること。
```
```
fix: ECSタスクがECRからイメージ取得できない問題を修正

VPCエンドポイントのセキュリティグループにECS SGからの
HTTPS（443）インバウンドが設定されていなかったため追加。
```
```
refactor: TerraformのVPCモジュールを分割

単一ファイルに全リソースが集中していたため以下に分割。
- vpc.tf        : VPC・IGW・ルートテーブル
- subnet.tf     : サブネット
- security_group.tf : セキュリティグループ
- endpoint.tf   : VPCエンドポイント
```

#### コミットメッセージの自動検証

現状は個人開発のため規約の遵守は手動運用とする。
チーム開発への移行時はhuskyを導入してコミット時に自動検証する方針とする。

| リポジトリ | 現状 | 今後の方針 |
| --- | --- | --- |
| `portfolio-app` | 手動運用 | husky導入予定（package.json既存のため導入容易） |
| `portfolio-infra` | 手動運用 | husky導入予定（npm init が必要） |

### GitHub Actions トリガー

| リポジトリ             | トリガー           | 実行内容                              |
| ----------------- | -------------- | --------------------------------- |
| `portfolio-infra` | Pull Request作成 | terraform fmt / validate / tflint / plan |
| `portfolio-infra` | mainブランチmerge  | terraform apply                   |
| `portfolio-app`   | Pull Request作成 | docker build / lint / test        |
| `portfolio-app`   | mainブランチmerge  | docker build → ECR push → ECSデプロイ |

#### CI/CDスキップ設定

`docs/**`配下のみの変更の場合はCI/CDをスキップする。
コードの変更を伴わないドキュメント修正でTerraform applyやECSデプロイが
実行されることを防止するため。
```yaml
on:
  push:
    branches:
      - main
    paths-ignore:
      - 'docs/**'
```

## 1.2. GitHub Actions設計（infraリポジトリ）

- リポジトリ：portfolio-infra
- TerraformによるAWSインフラ構成管理を行う。
- Terraform StateはS3 + DynamoDBで管理する

### CI（Pull Request）

PR作成時にTerraformコードの検証を行う。

| 処理 | 内容 |
| --- | --- |
| `terraform fmt` | コードフォーマットチェック |
| `terraform validate` | 構文チェック |
| `tflint` | ベストプラクティスチェック |
| `terraform plan` | インフラ変更内容の確認 |

#### tflint設定

| 項目 | 値 | 備考 |
| --- | --- | --- |
| 設定ファイル | `.tflint.hcl` | プロジェクトルートに配置 |
| AWSルールセット | `tflint-ruleset-aws` | AWSリソースのベストプラクティスチェック |
| モジュール解析 | `call_module_type = "local"` | ローカルモジュールも解析対象 |

#### 目的
- Terraformコード品質の担保
- インフラ変更内容の事前確認
- 誤った構成変更の防止
- AWSベストプラクティス違反の早期検知


### CD（mainブランチmerge）

- mainブランチへのmergeをトリガーに terraform apply を実行する。

| 処理                | 内容         |
| ----------------- | ---------- |
| `terraform init`  | backend初期化 |
| `terraform plan`  | 変更内容確認     |
| `terraform apply` | インフラ反映     |

#### 運用方針

- 直接 terraform apply は実行しない
- GitHub Actions経由のみインフラ変更を実施する

これにより以下を実現する。

- 操作履歴の可視化
- インフラ変更のトレーサビリティ確保

### ロールバック方針

Terraformのロールバックはコードベースを前のコミットに戻してapplyする方式をとる。
ECSのような自動ロールバックは存在しないため、手動での対応が必要となる。

#### ロールバック手順
```
1. 問題のあるコミットを特定
   git log --oneline

2. 前のコミットに戻す
   git revert <commit-sha>
   ※ git resetではなくgit revertを使用しhistoryを保持する

3. feature/revert-xxxブランチとしてpush・PR作成
   git checkout -b feature/revert-xxx
   git push origin feature/revert-xxx

4. PR経由でmainにmerge
   └─ GitHub ActionsがTerraform applyを実行して前の状態に戻る
```

#### 注意事項

| 項目 | 内容 |
| --- | --- |
| リソース再作成リスク | 変更内容によってはリソースの削除・再作成が発生する場合がある |
| 依存関係の考慮 | 他のリソースと依存関係がある場合は影響範囲を事前に確認する |
| terraform plan の確認 | apply前に必ずplanで変更内容を確認する |

## 1.3. GitHub Actions設計（appリポジトリ）

- リポジトリ：portfolio-app
- DockerイメージのビルドおよびECSデプロイを自動化する。

### CI（Pull Request）

PR作成時にDockerイメージのビルドおよびテストを行う。

| 処理             | 内容            |
| -------------- | ------------- |
| `docker build` | Dockerイメージビルド |
| `lint / test`  | アプリケーションテスト   |


#### 目的
- ビルド失敗の早期検知
- アプリケーション品質の担保


### CD（mainブランチmerge）

| 処理           | 内容              |
| ------------ | --------------- |
| `docker build` | Dockerイメージビルド   |
| `docker push`  | Amazon ECRへpush |
| `CodeDeploy`   | ECSデプロイ実行       |


#### イメージタグ戦略

| タグ | 形式 | 用途 |
| --- | --- | --- |
| gitsha タグ | `<gitsha>` | デプロイバージョンの追跡・ロールバック時の特定用 |
| latest タグ | `latest` | ECSタスク定義からの参照用 |

- nginx・app両イメージに同一のgitshaタグを付与することでセットのバージョンを管理する
- ECRへのpushはnginx・appの順で実行する
- ライフサイクルポリシーにより直近10世代のみ保持し、古いイメージは自動削除する（基本設計書6.6参照）

## 1.4. Blue/Greenデプロイ設計（CodeDeploy）

ECSサービスのデプロイは **AWS CodeDeployを利用したBlue/Greenデプロイ方式** を採用する。

### デプロイフロー
```
1. 新しいDockerイメージをECRへpush
2. CodeDeployが新しいタスクセットを起動
3. ALBのテストリスナーでヘルスチェック
4. 問題がなければ本番トラフィックを新タスクへ切替
5. 旧タスクセットを停止
```

### 採用理由
Blue/Greenデプロイを採用することで以下を実現する
| 項目       | 内容              |
| -------- | --------------- |
| ダウンタイム削減 | デプロイ中もサービス提供を継続 |
| 安全なリリース  | 新旧環境を分離してデプロイ   |
| ロールバック容易 | 問題発生時に旧環境へ戻せる   |


## 1.5. デプロイロールバック戦略

本システムでは AWS CodeDeploy を利用した Blue/Green デプロイ を採用している。
そのため、デプロイ失敗時には 自動ロールバック を実行することでサービス影響を最小化する。


### ロールバック方式

- CodeDeployの Auto Rollback 機能を利用する。
- ロールバックが発生した場合、トラフィックは旧タスクセットへ戻される。

```
旧タスクセット (Blue)
      ↑
      │ ロールバック
      │
新タスクセット (Green)
```

### ロールバック発生条件

以下の条件を満たした場合、自動ロールバックを実行する。

| 条件        | 内容                     |
| --------- | ---------------------- |
| デプロイ失敗    | CodeDeployのデプロイ処理が失敗   |
| ヘルスチェック失敗 | ALBターゲットグループのヘルスチェックNG |
| タスク起動失敗   | ECSタスクの起動エラー           |


### ロールバックフロー
```
1. GitHub Actions がデプロイ実行
2. CodeDeploy が新タスクセットを起動
3. ALB テストリスナーでヘルスチェック
4. 異常検知
5. CodeDeploy が自動ロールバック
6. 旧タスクセットへトラフィック復帰
```

### 手動ロールバック手順

自動ロールバックが行われない場合は、以下の手順で手動ロールバックを実施する。

#### 手順

1. AWS Management Console にログイン
2. CodeDeploy → 対象アプリケーションを選択
3. Deployment History を確認
4. 直前の成功デプロイを選択
5. 「Redeploy」を実行

これにより、直前の安定バージョンへ復旧する。


### ロールバック時の調査項目

ロールバック発生時は以下のログを確認する。

| 確認対象            | 確認内容        |
| --------------- | ----------- |
| ECSログ           | コンテナ起動エラー   |
| CloudWatch Logs | アプリケーションエラー |
| ALBヘルスチェック      | HTTPレスポンス異常 |
| CodeDeployログ    | デプロイ失敗原因    |


## 1.6. GitHub Actions認証方式

GitHub ActionsからAWSへのアクセスはOpenID Connect（OIDC）を利用して
IAMロールをAssumeする方式とする。
アクセスキーを発行・管理する必要がなくなるため、シークレット漏洩リスクを排除できる。

### アクセスキー方式との比較

| | アクセスキー | OIDC |
| --- | --- | --- |
| 認証情報の保存 | GitHub Secretsに保存が必要 | 不要 |
| 有効期限 | 永続（手動ローテーション必要） | 一時的（自動失効） |
| 漏洩リスク | 高い | 低い |
| 管理コスト | ローテーション運用が必要 | ほぼ不要 |
| 権限の絞り込み | ユーザー単位 | リポジトリ・ブランチ単位まで可能 |

### 仕組み
```
①GitHub Actionsのワークフロー実行
        │
        │ ②GitHubのOIDC Providerに
        │   「このリポジトリで実行中」という
        │   JWTトークンを発行してもらう
        ▼
┌─────────────────┐
│  GitHub OIDC    │
│  Provider       │
└────────┬────────┘
         │ ③JWTトークンを持ってAWSに
         │   「このロールを使わせてください」
         │   とリクエスト
         ▼
┌─────────────────┐
│   AWS STS       │  ④JWTトークンを検証
│  (一時認証基盤)  │   ・GitHubのPublic Keyで署名確認
│                 │   ・リポジトリ名・ブランチが
│                 │     IAMロールの信頼ポリシーと一致するか確認
└────────┬────────┘
         │ ⑤検証OK → 一時的な認証情報を発行
         │  （有効期限付き・使い捨て）
         ▼
┌─────────────────┐
│   IAMロール     │
│                 │
│ 信頼ポリシー：  │
│ ・GitHub OIDCを │
│   信頼する      │
│ ・対象リポジトリ │
│   のみ許可      │
└────────┬────────┘
         │ ⑥一時認証情報でAWSリソースを操作
         ▼
   ECR push / ECSデプロイ 等
```

### JWTトークンの中身（イメージ）

GitHubが発行するJWTには以下のような情報が含まれる。
AWSはこの情報をもとに「どのリポジトリ・ブランチからの実行か」を検証する。
```json
{
  "iss": "https://token.actions.githubusercontent.com",
  "repository": "yourname/portfolio-app",
  "ref": "refs/heads/main",
  "job_workflow_ref": "yourname/portfolio-app/.github/workflows/deploy.yml"
}
```

### トークンライフサイクル

作り直しや手動ローテーションは不要。ワークフローが実行されるたびに自動的に新しいトークンが発行される。
```
git push
  │
  ▼
GitHub Actionsワークフロー起動
  │
  ├─ ① 起動時にGitHubがJWTトークンを自動発行（有効期限：数分〜1時間程度）
  │
  ├─ ② AWSから一時認証情報を取得（有効期限：最大1時間）
  │
  ├─ ③ ECR push / ECSデプロイ 等を実行
  │
  └─ ④ ワークフロー終了 → トークン・認証情報は自動失効

次のgit pushでまた①から繰り返す
```

### IAMロール設計

| ロール名 | 対象リポジトリ | 付与ポリシー | 用途 |
| --- | --- | --- | --- |
| `dev-portfolio-identity-github-actions-infra-role` | `portfolio-infra` | AdministratorAccess | Terraform apply |
| `dev-portfolio-identity-github-actions-app-role` | `portfolio-app` | カスタムポリシー | ECR push / ECSデプロイ |

※ infra用ロールのAdministratorAccessは本番運用時に最小権限ポリシーへ絞る方針とする。

### 信頼ポリシー（実装イメージ）
```json
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:sub":
        "repo:yourname/portfolio-app:ref:refs/heads/main"
    }
  }
}
```

`Condition`でリポジトリ名・ブランチまで絞り込めるためセキュリティが高い。

### 実装手順

#### AWS側
```
STEP 1: IAM Identity Providerの作成
  │
  │ IAM → IDプロバイダ → プロバイダを追加
  │   プロバイダのタイプ : OpenID Connect
  │   プロバイダURL     : https://token.actions.githubusercontent.com
  │   対象者(Audience) : sts.amazonaws.com
  │
  ▼
STEP 2: IAMロールの作成（infra用）
  │
  │ 信頼ポリシー：
  │   ・Federated: 上記で作成したIDプロバイダのARN
  │   ・Condition: portfolio-infraリポジトリに限定
  │ 付与ポリシー：AdministratorAccess
  │   ※本番運用時は最小権限ポリシーに絞る方針
  │
  ▼
STEP 3: IAMロールの作成（app用）
  │
  │ 信頼ポリシー：
  │   ・Federated: 上記で作成したIDプロバイダのARN
  │   ・Condition: portfolio-appリポジトリに限定
  │ 付与ポリシー：カスタムポリシー（ECR push / ECSデプロイ / CodeDeploy）
  │
  ▼
STEP 4: 各ロールのARNを控える
    → GitHub側の設定で使用する
```

#### GitHub側
```
STEP 1: リポジトリのSecretsにロールARNを登録
  │
  │ portfolio-infraリポジトリ：
  │   Settings → Secrets and variables → Actions → New repository secret
  │   Name  : AWS_ROLE_ARN
  │   Value : arn:aws:iam::<account-id>:role/dev-portfolio-identity-github-actions-infra-role
  │
  │ portfolio-appリポジトリ：
  │   Settings → Secrets and variables → Actions → New repository secret
  │   Name  : AWS_ROLE_ARN
  │   Value : arn:aws:iam::<account-id>:role/dev-portfolio-identity-github-actions-app-role
  │
  ▼
STEP 2: ワークフローファイルにOIDC設定を追記
  │
  │ 以下の2点が必要：
  │   ① permissionsブロックでid-token: writeを付与
  │   ② aws-actions/configure-aws-credentialsでロールを引き受ける
  │
  ▼
STEP 3: ワークフローファイルの実装イメージ
```

### ワークフロー実装イメージ
```yaml
jobs:
  deploy:
    permissions:
      id-token: write   # OIDCトークン発行に必要
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ap-northeast-1
      # 以降は通常通りAWSコマンドが使用可能
```

# 2. 監視・ログ設計

## 2.1. 概要

本システムの監視・ログ設計は以下の2つを軸とする。

| 種別 | ツール | 用途 |
| --- | --- | --- |
| アプリケーションログ | CloudWatch Logs | ECSコンテナのログ収集・確認 |
| アクセスログ | S3 + ALB | HTTPアクセス履歴の保存・分析 |
| アラート | CloudWatch Alarm + SNS | 異常検知・メール通知 |

### ログ確認が必要なシーン

| シーン | 確認するログ | 確認場所 |
| --- | --- | --- |
| アプリケーションエラー発生時 | PHP-FPMログ | CloudWatch Logs |
| nginxエラー発生時 | nginxログ | CloudWatch Logs |
| デプロイ失敗時 | nginx・PHP-FPMログ | CloudWatch Logs |
| 不審なアクセス調査時 | ALBアクセスログ | S3 |
| パフォーマンス調査時 | ALBアクセスログ・応答時間 | S3 / CloudWatch |
| RDSフェールオーバー発生時 | RDSイベントログ | CloudWatch Logs / RDSコンソール |

## 2.2. CloudWatch Logs設計

### ロググループ設計

| ロググループ | 保持期間 | 用途 |
| --- | --- | --- |
| `/ecs/dev-portfolio-nginx` | 30日 | nginxアクセスログ・エラーログ |
| `/ecs/dev-portfolio-php-fpm` | 30日 | PHPアプリケーションログ・エラーログ |

**保持期間を30日に設定した理由：**
- 障害調査に必要な期間として30日あれば十分と判断
- 長期保存はS3へのエクスポートで対応する方針（コスト削減）

### ログ確認方法

#### AWSマネジメントコンソールから確認
```
CloudWatch → ロググループ → 対象ロググループを選択
→ ログストリームを選択 → ログイベントを確認
```

#### AWS CLIから確認
```bash
# 直近のnginxログを確認
aws logs tail /ecs/dev-portfolio-nginx \
  --follow \
  --profile portfolio-dev

# 直近のPHP-FPMログを確認
aws logs tail /ecs/dev-portfolio-php-fpm \
  --follow \
  --profile portfolio-dev

# キーワードで絞り込む場合
aws logs filter-log-events \
  --log-group-name /ecs/dev-portfolio-php-fpm \
  --filter-pattern "ERROR" \
  --profile portfolio-dev
```

### 運用ルール

| シーン | 確認対象ロググループ | 確認内容 |
| --- | --- | --- |
| アプリケーションエラー発生時 | `/ecs/dev-portfolio-php-fpm` | Laravelのエラーログ・スタックトレース |
| 画面が表示されない場合 | `/ecs/dev-portfolio-nginx` | 502/503エラー・upstream接続エラー |
| デプロイ後に異常が発生した場合 | 両ロググループ | デプロイ前後のログを比較 |
| パフォーマンス劣化時 | `/ecs/dev-portfolio-nginx` | レスポンスタイム・リクエスト数 |

## 2.3. ALBアクセスログ設計

### 概要

ALBのアクセスログをS3バケットに保存する。
アクセス履歴・不審なリクエストの調査・パフォーマンス分析に使用する。

### 設定値

| 項目 | 値 | 備考 |
| --- | --- | --- |
| 保存先バケット | `com-infra-nikki-dev-portfolio-s3-alb-logs-<suffix>` | 命名規則に準拠 |
| プレフィックス | `alb-logs/` | ログの格納パス |
| バケットポリシー | ALBサービスアカウントからの書き込みを許可 | AWSが管理するELBサービスアカウントを許可 |
| ライフサイクル | 90日後に自動削除 | コスト削減 |

### ログフォーマット

ALBアクセスログには以下の情報が含まれる。

| フィールド | 内容 |
| --- | --- |
| timestamp | リクエスト受信時刻 |
| elb | ALB名 |
| client:port | クライアントIPアドレス・ポート |
| request | HTTPメソッド・URL・プロトコル |
| target_status_code | ターゲット（ECS）のHTTPステータスコード |
| elb_status_code | ALBが返すHTTPステータスコード |
| response_processing_time | ALBがレスポンスを処理した時間 |
| user_agent | クライアントのUser-Agent |

### ログ確認方法

#### S3コンソールから確認
```
S3 → com-infra-nikki-dev-portfolio-s3-alb-logs-<suffix>
→ alb-logs/ → 年/月/日 のフォルダ構造でログが格納されている
→ 対象ファイルをダウンロードして確認
```

#### AWS CLIから確認
```bash
# ログファイルの一覧を確認
aws s3 ls s3://com-infra-nikki-dev-portfolio-s3-alb-logs-<suffix>/alb-logs/ \
  --recursive \
  --profile portfolio-dev

# ログファイルをダウンロード
aws s3 cp s3://com-infra-nikki-dev-portfolio-s3-alb-logs-<suffix>/alb-logs/<path>/<file> \
  ./alb-access.log \
  --profile portfolio-dev

# ダウンロードしたログからエラーを抽出
grep " 5[0-9][0-9] " alb-access.log
```

### 運用ルール

| シーン | 確認内容 |
| --- | --- |
| 不審なアクセスの調査 | 特定IPからの大量リクエスト・異常なUser-Agent |
| 5xxエラーの調査 | エラー発生時刻・リクエストURL・ステータスコード |
| パフォーマンス調査 | response_processing_timeが長いリクエストの特定 |
| セキュリティ監査 | 定期的なアクセスパターンの確認 |

## 2.4. アラート設計

### 基本方針

- CloudWatch アラームを使用してシステムの異常を検知する
- アラーム発報時はメールで通知する（Amazon SNS経由）
- ポートフォリオ用途のため最小限のアラームを設定する

### SNS設定

| 項目 | 値 | 備考 |
| --- | --- | --- |
| トピック名 | `dev-portfolio-alarm-topic` | アラーム通知用 |
| 通知先 | AWSアカウントのメールアドレス | |

### アラーム一覧

#### ECS

| アラーム名 | メトリクス | 閾値 | 評価期間 | 備考 |
| --- | --- | --- | --- | --- |
| `dev-portfolio-ecs-cpu-high` | ECS CPU使用率 | 80%以上 | 2回連続 | スケールアウト前の異常検知 |
| `dev-portfolio-ecs-memory-high` | ECSメモリ使用率 | 80%以上 | 2回連続 | メモリ枯渇の検知 |

#### ALB

| アラーム名 | メトリクス | 閾値 | 評価期間 | 備考 |
| --- | --- | --- | --- | --- |
| `dev-portfolio-alb-5xx-error` | HTTPCode_Target_5XX_Count | 10回以上/分 | 2回連続 | アプリケーションエラーの検知 |
| `dev-portfolio-alb-response-time` | TargetResponseTime | 3秒以上 | 2回連続 | パフォーマンス劣化の検知 |

#### RDS

| アラーム名 | メトリクス | 閾値 | 評価期間 | 備考 |
| --- | --- | --- | --- | --- |
| `dev-portfolio-rds-cpu-high` | RDS CPU使用率 | 80%以上 | 2回連続 | DB負荷の検知 |
| `dev-portfolio-rds-connections-high` | DatabaseConnections | 50以上 | 2回連続 | 接続数枯渇の検知 |

### 通知フロー
```
CloudWatch アラーム
        │
        │ 閾値超過
        ▼
    Amazon SNS
        │
        │ メール通知
        ▼
   メールアドレス
        │
        │ 確認・対応
        ▼
   障害対応フロー（5章参照）
```

### Auto Scalingアラームについて

以下の2つはECS Auto Scalingが自動生成するアラームであり手動管理対象外とする。

| アラーム | 用途 |
| --- | --- |
| `TargetTracking-...-AlarmHigh` | CPU使用率高騰時のスケールアウト用 |
| `TargetTracking-...-AlarmLow` | CPU使用率低下時のスケールイン用 |



# 3. バックアップ・リストア設計

## 3.1. 概要

本システムのバックアップ・リストアはRDSの自動バックアップ機能を使用する。

| 項目 | 内容 |
| --- | --- |
| 対象 | RDS（MariaDB） |
| 方式 | RDS自動バックアップ（ポイントインタイムリカバリ） |
| 保持期間 | 1日間 |
| リストア方式 | 新規RDSインスタンスとして復元後、接続先を切り替え |

**手動スナップショットについて：**
自動バックアップと同様の操作を手動で行うものであり、本システムでは運用対象外とする。
必要に応じてAWSマネジメントコンソールから手動取得することは可能。

## 3.2. RDSバックアップ設計

### バックアップ設定

| 項目 | 値 | 備考 |
| --- | --- | --- |
| 自動バックアップ | 有効 | |
| バックアップ保持期間 | 1日間 | コスト削減のため最小値に設定 |
| バックアップウィンドウ | 18:00〜19:00 UTC（03:00〜04:00 JST） | 深夜帯に設定 |

**保持期間を1日に設定した理由：**
ポートフォリオ用途のためコスト削減を優先し最小値（1日）に設定する。
本番運用時は要件に応じて7日以上に設定することを推奨する。

### ポイントインタイムリカバリについて

RDSの自動バックアップはポイントインタイムリカバリ（PITR）に対応している。
保持期間内であれば**任意の時点**に復元できる。
```
現在
  │
  │← 保持期間（1日）→│
  │                  │
  ▼                  ▼
復元可能な範囲      最古の復元ポイント
```

## 3.3. リストア手順

### 前提

- リストアは既存のRDSインスタンスを上書きするのではなく**新規インスタンスとして復元**する
- 復元後にアプリケーションの接続先（SSM Parameter Store）を新インスタンスのエンドポイントに変更する
- リストア作業中はサービスが一時停止する

### リストア手順
```
STEP 1: 復元ポイントの確認
  │
  │ RDS → dev-portfolio-database-rds
  │ → メンテナンスとバックアップ → バックアップ
  │ → 「最も遅い復元可能な時刻」を確認
  │
  ▼
STEP 2: 新規RDSインスタンスとして復元
  │
  │ RDS → dev-portfolio-database-rds
  │ → 「アクション」→「ポイントインタイムに復元」
  │ → 復元する日時を指定
  │ → 新しいインスタンス識別子を入力
  │   例：dev-portfolio-database-rds-restored
  │ → 「インスタンスの復元」を実行
  │
  ▼
STEP 3: 復元完了の確認
  │
  │ RDS → 復元したインスタンスのステータスが
  │ 「利用可能」になるまで待機（目安：10〜20分）
  │
  ▼
STEP 4: SSM Parameter Storeの接続先を更新
  │
  │ Systems Manager → パラメータストア
  │ → DB_HOST の値を復元したインスタンスのエンドポイントに変更
  │
  │ CLIで更新する場合：
  │ aws ssm put-parameter \
  │   --name "/dev/portfolio/DB_HOST" \
  │   --value "<復元したインスタンスのエンドポイント>" \
  │   --overwrite \
  │   --profile portfolio-dev
  │
  ▼
STEP 5: ECSタスクを再起動
  │
  │ ECSタスクは起動時にSSMから接続先を取得するため
  │ タスクを再起動して新しい接続先を反映させる
  │
  │ aws ecs update-service \
  │   --cluster dev-portfolio-container-ecs-cluster \
  │   --service dev-portfolio-container-ecs-service \
  │   --force-new-deployment \
  │   --profile portfolio-dev
  │
  ▼
STEP 6: 動作確認
  │
  │ ① ブラウザから https://portfolio.infra-nikki.com にアクセス
  │ ② ログインが正常にできることを確認
  │ ③ データが期待通りに復元されていることを確認
  │ ④ CloudWatch Logsでエラーが出ていないことを確認
  │
  ▼
STEP 7: 旧インスタンスの削除（復元確認後）
  │
  │ 動作確認完了後、不要になった旧インスタンスを削除する
  │ ※ 削除前に最終スナップショットを取得することを推奨
  │
  └─ RDS → dev-portfolio-database-rds → 削除
```

### リストア時の注意事項

| 項目 | 内容 |
| --- | --- |
| ダウンタイム | STEP4〜5の切り替え作業中はサービスが一時停止する |
| セキュリティグループ | 復元したインスタンスに正しいSGが設定されているか確認する |
| パラメータグループ | カスタムパラメータグループが適用されているか確認する |
| マルチAZ | 復元時はシングルAZで復元されるためマルチAZに変更が必要 |



# 4. コスト管理設計

## 4.1. 概要

本システムのコスト管理はAWS Budgetsを使用して月額コストを監視する。
予算超過の早期検知を目的としてアラートを設定し、メールで通知する。

### 月額コスト試算

詳細は基本設計書4章を参照。

| 項目 | 値 |
| --- | --- |
| 月額試算 | 約121USD |
| 予算上限 | 150USD（約20,000円） |

## 4.2. AWS Budgets設計

### 予算設定

| 項目 | 値 | 備考 |
| --- | --- | --- |
| 予算名 | `My Monthly Cost Budget` | |
| 予算タイプ | コスト予算 | |
| 予算期間 | 月次 | |
| 予算額 | 150USD | 約20,000円（1USD=133円換算） |
| 通知先 | AWSアカウントのメールアドレス | |

**予算額をJPYで設定できない理由：**
AWS BudgetsはUSD単位でのみ予算設定が可能なため、
20,000円をUSD換算した150USDで設定する。
為替レートの変動により実際の円換算額は変動する点に注意する。

### アラート設定

| 通知タイプ | 閾値 | 通知タイミング | 備考 |
| --- | --- | --- | --- |
| 実績ベース | 80%（120USD） | 実績が120USDを超過した時点 | 事前通知 |
| 実績ベース | 100%（150USD） | 実績が150USDを超過した時点 | 超過通知 |
| 予測ベース | 100%（150USD） | 予測が150USDを超える見込みになった時点 | 超過予測通知 |

**予測ベースアラートについて：**
月末時点での超過が予測される場合に事前通知する。
実績ベースの通知より早い段階で超過リスクを検知できる。

### 通知フロー
```
AWS Budgets
    │
    │ 閾値超過（実績 or 予測）
    ▼
メール通知
    │
    │ 確認・対応
    ▼
コスト最適化対応（4.3参照）
```

## 4.3. コスト最適化方針

### 現状のコスト削減施策

実施済みのコスト削減施策は以下の通り。詳細は基本設計書4.2を参照。

| 施策 | 削減効果 |
| --- | --- |
| VPCエンドポイント1AZ配置（NATゲートウェイ代替） | 約$5/月削減 |
| VPCエンドポイント2AZから1AZに削減 | 約$40/月削減 |
| RDSインスタンスクラスをt3.microに設定 | 上位クラス比で削減 |
| ECRライフサイクルポリシーで直近10世代のみ保持 | ストレージ削減 |
| ALBアクセスログのライフサイクルを90日に設定 | ストレージ削減 |
| RDSバックアップ保持期間を1日に設定 | ストレージ削減 |

### 予算超過時の対応方針

| 状況 | 対応 |
| --- | --- |
| 80%アラート発報時 | コストエクスプローラーで増加要因を確認 |
| 100%アラート発報時 | 不要なリソースの停止・削除を検討 |
| 予測ベースアラート発報時 | 月末までの推移を確認し早期に対処 |

### コスト確認方法

#### AWSマネジメントコンソールから確認
```
AWS Cost Explorer → コストと使用状況
→ サービス別・日別でコストを確認
```

#### AWS CLIから確認
```bash
# 今月のサービス別コストを確認
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --profile portfolio-dev
```



# 5. 障害対応設計

## 5.1. 概要

本システムの障害対応は以下の流れを基本とする。
```
障害検知（アラーム発報 or エンドユーザ報告）
    │
    ▼
障害内容の確認・切り分け
    │
    ├─ ECSタスク障害 → 5.3参照
    ├─ RDSフェールオーバー → 5.4参照
    └─ その他 → ログ確認・原因調査
```

### 障害レベル定義

| レベル | 内容 | 例 |
| --- | --- | --- |
| Critical | サービス全停止 | ECSタスク全停止・RDS接続不可 |
| Warning | サービス品質低下 | レスポンスタイム遅延・一部エラー発生 |
| Info | 軽微な異常 | CPU使用率高騰・メモリ使用率上昇 |

## 5.2. 障害検知フロー

### パターンA：CloudWatchアラーム発報による検知
```
① CloudWatchアラーム発報
   │
   │ 検知対象：
   │   ・ECS CPU/メモリ使用率80%超
   │   ・ALB 5xxエラー率上昇
   │   ・ALBレスポンスタイム3秒超
   │   ・RDS CPU使用率80%超
   │   ・RDS DB接続数50超
   │
   ▼
② SNS経由でメール通知受信
   │
   ▼
③ AWSマネジメントコンソールにログイン
   │
   ▼
④ 障害内容の確認・切り分け（下記の初動確認コマンドを使用）
   │
   ▼
⑤ 障害種別に応じた対応へ（5.3・5.4参照）
```

### パターンB：エンドユーザからの障害報告による検知
```
① エンドユーザから「画面にアクセスできない」旨の報告
   │
   ▼
② 自分でもアクセスして症状を確認
   │
   │ 症状別の原因候補：
   │
   │ ・502 Bad Gateway
   │     → ECSタスク障害・nginxエラーの可能性
   │
   │ ・503 Service Unavailable
   │     → ECSタスクが全停止・ヘルスチェック全滅の可能性
   │
   │ ・画面がタイムアウト・表示されない
   │     → ALB障害・DNS障害の可能性
   │
   │ ・ログインできない
   │     → PHP-FPM障害・RDS接続エラーの可能性
   │
   │ ・特定のページだけエラー
   │     → アプリケーションエラーの可能性
   │
   ▼
③ AWSマネジメントコンソールにログイン
   │
   ▼
④ 障害内容の確認・切り分け（下記の初動確認コマンドを使用）
   │
   ▼
⑤ 障害種別に応じた対応へ（5.3・5.4参照）
```

### 初動確認コマンド
```bash
# ECSタスクの状態確認
aws ecs describe-services \
  --cluster dev-portfolio-container-ecs-cluster \
  --services dev-portfolio-container-ecs-service \
  --query 'services[*].{status:status,running:runningCount,desired:desiredCount}' \
  --output table \
  --profile portfolio-dev

# RDSの状態確認
aws rds describe-db-instances \
  --db-instance-identifier dev-portfolio-database-rds \
  --query 'DBInstances[*].{status:DBInstanceStatus,az:AvailabilityZone}' \
  --output table \
  --profile portfolio-dev

# 直近のnginxエラーログ確認
aws logs filter-log-events \
  --log-group-name /ecs/dev-portfolio-nginx \
  --filter-pattern "error" \
  --profile portfolio-dev

# 直近のPHP-FPMエラーログ確認
aws logs filter-log-events \
  --log-group-name /ecs/dev-portfolio-php-fpm \
  --filter-pattern "ERROR" \
  --profile portfolio-dev
```

## 5.3. ECSタスク障害時の対応

### 障害パターンと対応

| パターン | 症状 | 対応 |
| --- | --- | --- |
| タスクが起動しない | runningCountが0 | ログ確認・タスク定義の確認 |
| タスクが繰り返し再起動する | タスクが頻繁に入れ替わる | アプリケーションエラーログを確認 |
| ヘルスチェック失敗 | ALBがUnhealthyを検知 | `/login`エンドポイントの応答確認 |
| デプロイ失敗 | CodeDeployがロールバック | 1.5参照 |
| 502 Bad Gateway | nginxがPHP-FPMに接続できない | PHP-FPMコンテナの状態・ログを確認 |
| 503 Service Unavailable | タスクが全停止・ヘルスチェック全滅 | タスクの強制再起動を実施 |

### 対応手順
```
STEP 1: タスクの状態確認
  │
  │ ECS → dev-portfolio-container-ecs-cluster
  │ → dev-portfolio-container-ecs-service → タスクタブ
  │ → 停止したタスクのステータス・停止理由を確認
  │
  ▼
STEP 2: ログの確認
  │
  │ CloudWatch Logs
  │ → /ecs/dev-portfolio-nginx
  │ → /ecs/dev-portfolio-php-fpm
  │ → エラーメッセージ・スタックトレースを確認
  │
  ▼
STEP 3: 原因の特定と対応
  │
  │ ・アプリケーションエラー → コード修正してデプロイ
  │ ・SSM Parameter Store接続エラー → IAMロール・VPCエンドポイントを確認
  │ ・ECRイメージ取得エラー → ECRリポジトリ・IAMロールを確認
  │ ・メモリ不足 → タスク定義のメモリ設定を見直し
  │
  ▼
STEP 4: タスクの強制再起動（必要な場合）
  │
  │ aws ecs update-service \
  │   --cluster dev-portfolio-container-ecs-cluster \
  │   --service dev-portfolio-container-ecs-service \
  │   --force-new-deployment \
  │   --profile portfolio-dev
  │
  ▼
STEP 5: 動作確認
    └─ https://portfolio.infra-nikki.com にアクセスして正常稼働を確認
```

## 5.4. RDSフェールオーバー対応

### フェールオーバーの動作

| フェーズ | 内容 |
| --- | --- |
| 通常時 | プライマリ（1a）が読み書きを処理 |
| フェールオーバー発生 | スタンバイ（1c）がプライマリに自動昇格（60〜120秒） |
| 切り替え後 | RDSエンドポイント（DNS）が新プライマリを自動的に指し替え |

**アプリケーション側の接続先変更は不要。**
ECSタスクはRDSエンドポイント（DNS名）で接続しているため、
フェールオーバー後も自動的に新プライマリに接続される。

### フェールオーバー発生時の対応手順
```
STEP 1: フェールオーバーの検知
  │
  │ ・CloudWatchアラーム（RDS CPU使用率）発報
  │ ・RDSコンソールでイベントログを確認
  │
  │ aws rds describe-events \
  │   --source-identifier dev-portfolio-database-rds \
  │   --source-type db-instance \
  │   --profile portfolio-dev
  │
  ▼
STEP 2: フェールオーバー完了の確認
  │
  │ aws rds describe-db-instances \
  │   --db-instance-identifier dev-portfolio-database-rds \
  │   --query 'DBInstances[*].{status:DBInstanceStatus,az:AvailabilityZone}' \
  │   --output table \
  │   --profile portfolio-dev
  │
  │ → ステータスが「利用可能」・AZが1cに切り替わっていることを確認
  │
  ▼
STEP 3: アプリケーションの動作確認
  │
  │ ① https://portfolio.infra-nikki.com にアクセス
  │ ② ログイン・データ参照が正常にできることを確認
  │ ③ CloudWatch Logsでエラーが出ていないことを確認
  │
  ▼
STEP 4: ECSタスクの再起動（接続が回復しない場合）
  │
  │ DNSキャッシュが残っている場合はタスクを再起動して接続先を更新する
  │
  │ aws ecs update-service \
  │   --cluster dev-portfolio-container-ecs-cluster \
  │   --service dev-portfolio-container-ecs-service \
  │   --force-new-deployment \
  │   --profile portfolio-dev
  │
  ▼
STEP 5: 原因調査・再発防止
    └─ RDSイベントログ・CloudWatch Logsで障害原因を確認
```

### 手動フェールオーバー（試験時）

フェールオーバー試験はRDSコンソールから実施する。
```
RDS → dev-portfolio-database-rds
→「アクション」→「フェールオーバー」→ 実行
```

※ 試験手順の詳細は試験仕様書に記載する。



# 6. セキュリティ運用設計

## 6.1. IAM運用方針

### 基本方針

- 最小権限の原則を適用する
- ルートユーザーは日常的に使用しない
- アクセスキーは必要最小限のユーザーにのみ発行する
- GitHub ActionsからのAWSアクセスはOIDCを使用する（詳細は1.6参照）

### IAMユーザー運用

| ユーザー | 運用ルール |
| --- | --- |
| ルートユーザー | MFA必須・日常利用禁止・アクセスキー発行禁止 |
| `admin-<name>` | コンソールログイン時はMFA必須 |
| `terraform-user` | 90日ごとにアクセスキーをローテーション |

### アクセスキーローテーション

90日ごとに手動でローテーションを実施する。
```
STEP 1: 新しいアクセスキーを発行
  │
  │ IAM → ユーザー → terraform-user
  │ → セキュリティ認証情報 → アクセスキーを作成
  │
  ▼
STEP 2: 新しいアクセスキーをローカルに設定
  │
  │ aws configure --profile portfolio-dev
  │
  ▼
STEP 3: 動作確認
  │
  │ aws sts get-caller-identity --profile portfolio-dev
  │
  ▼
STEP 4: 旧アクセスキーを無効化・削除
  │
  │ IAM → ユーザー → terraform-user
  │ → セキュリティ認証情報 → 旧アクセスキーを無効化 → 削除
```

### 定期確認項目

| 確認項目 | 頻度 | 確認方法 |
| --- | --- | --- |
| アクセスキーのローテーション | 90日ごと | IAMコンソール → terraform-userのセキュリティ認証情報 |
| 未使用のIAMユーザー・ロールの確認 | 月次 | IAMコンソール → 認証情報レポート |
| アクセスキーの最終使用日確認 | 月次 | IAMコンソール → 認証情報レポート |
| MFA設定状況の確認 | 月次 | IAMコンソール → ユーザー一覧 |
| IAMポリシーの過剰権限確認 | 四半期 | IAM Access Analyzer |

#### 認証情報レポートの取得
```bash
# 認証情報レポートを生成
aws iam generate-credential-report \
  --profile portfolio-dev

# レポートを取得
aws iam get-credential-report \
  --query 'Content' \
  --output text \
  --profile portfolio-dev | base64 -d
```

## 6.2. CloudTrail・AWS Config運用

### CloudTrail運用

#### 概要

| 項目 | 値 | 備考 |
| --- | --- | --- |
| 有効化 | 済み | Day1対応 |
| 記録対象 | 管理イベント | デフォルト設定 |
| ログ保存先 | AWSが自動生成したS3バケット | |
| 設定方針 | デフォルト設定のまま運用 | |

#### ログ確認方針

CloudTrailのログはアラーム発報時・障害発生時・不審な操作が疑われる場合に確認する。
定期的な確認は実施しない。

#### 確認が必要なシーン

| シーン | 確認内容 |
| --- | --- |
| 不審なAWS操作が疑われる場合 | 操作履歴・操作元IPアドレスの確認 |
| リソースが意図せず変更された場合 | 変更操作の実行者・実行時刻の確認 |
| セキュリティインシデント発生時 | 不正アクセスの有無・操作内容の確認 |

#### ログ確認方法
```
AWSマネジメントコンソール：
CloudTrail → イベント履歴
→ フィルター（ユーザー名・リソース・時間）で絞り込み
```
```bash
# 直近のEC2関連イベントを確認
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::EC2::Instance \
  --profile portfolio-dev

# 特定ユーザーの操作履歴を確認
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=terraform-user \
  --profile portfolio-dev
```

### AWS Config運用

#### 概要

| 項目 | 値 | 備考 |
| --- | --- | --- |
| 有効化 | 済み | Day1対応 |
| 記録対象 | リソース構成変更 | デフォルト設定 |
| 保存先 | AWSが自動生成したS3バケット | |
| 設定方針 | デフォルト設定のまま運用 | |

#### ログ確認方針

AWS Configのログはアラーム発報時・障害発生時・リソースの設定が意図せず変更された場合に確認する。
定期的な確認は実施しない。

#### 確認が必要なシーン

| シーン | 確認内容 |
| --- | --- |
| リソースの設定が意図せず変更された場合 | 変更前後の設定値の比較 |
| セキュリティグループのルールが変わった場合 | 変更履歴・変更内容の確認 |
| コンプライアンス確認時 | リソースの設定がルールに準拠しているか確認 |

#### 確認方法
```
AWSマネジメントコンソール：
AWS Config → リソース
→ 対象リソースを選択 → 設定タイムラインで変更履歴を確認
```

### セキュリティインシデント発生時の対応フロー
```
① 不審な操作・アクセスを検知
   │
   ▼
② CloudTrailで操作履歴を確認
   │
   │ ・操作元IPアドレスの確認
   │ ・操作内容・実行時刻の確認
   │ ・対象リソースの確認
   │
   ▼
③ 影響範囲の特定
   │
   │ ・AWS Configで変更されたリソースを確認
   │ ・変更前後の設定値を比較
   │
   ▼
④ 緊急対応
   │
   │ ・不審なIAMユーザーのアクセスキーを即時無効化
   │ ・不審なリソースの隔離・停止
   │ ・セキュリティグループで不審なIPをブロック
   │
   ▼
⑤ 原因調査・再発防止策の実施
```

# 7. 運用Runbook

## 7.1. 概要

本システムは以下の理由により、個別のRunbookが必要な定期運用手順は最小限となっている。

| 項目 | 理由 |
| --- | --- |
| SSL/TLS証明書更新 | ACMによる自動更新のため手動対応不要 |
| ドメイン更新 | レジストラの自動更新設定のため手動対応不要 |
| ECS再起動 | 障害発生時の対応手順として5.3に記載済み |
| インフラ変更 | GitHub Actions経由のTerraform applyで自動化済み |
| アプリデプロイ | GitHub Actions経由のBlue/Greenデプロイで自動化済み |

定期運用が必要な手順はIAMアクセスキーのローテーション（90日ごと）のみであり、
手順は6.1に記載済みとする。


# 8. SLO（サービスレベル目標）

## 8.1. 可用性目標

### コンポーネント別SLO

| コンポーネント | 可用性 | 根拠 |
| --- | --- | --- |
| ALB | 99.99% | AWSのSLA準拠 |
| ECS（Fargate） | 99.99% | AWSのSLA準拠 |
| RDS（マルチAZ） | 99.95% | AWSのSLA準拠 |

### システム全体SLO

| 項目 | 値 | 備考 |
| --- | --- | --- |
| 目標可用性 | 99.93% | ALB×ECS×RDSの可用性の積 |
| 月間許容ダウンタイム | 約30分 | 99.93%換算 |