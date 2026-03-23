# AWS デプロイメントガイド

## CI/CDサービスの選択肢

### AWS CodePipeline + CodeBuild（推奨）
AWSネイティブのCI/CDサービス。IAMとの統合が容易で、CDK/CloudFormationとの連携が自然。

**パイプライン構成：**
```
CodeCommit/GitHub → CodeBuild(Build) → CodeBuild(Test) → CloudFormation(Staging)
→ CodeBuild(SmokeTest) → 手動承認 → CloudFormation(Prod)
```

**CodeBuild buildspec.yml の構成：**
```yaml
phases:
  install:
    runtime-versions:
      python: 3.12
    commands:
      - pip install -r requirements.txt
  build:
    commands:
      - python -m pytest tests/unit/ -v
      - python -m pytest tests/integration/ -v
  post_build:
    commands:
      - cdk synth
artifacts:
  files:
    - '**/*'
```

### GitHub Actions + AWS CDK
GitHub上のリポジトリの場合の選択肢。OIDC連携でIAMロールを利用。

### その他
- AWS Proton — テンプレートベースの環境管理
- AWS App Runner — コンテナベースのアプリケーション

---

## 環境管理

### AWSアカウント戦略

**推奨：マルチアカウント構成**
| 環境 | AWSアカウント | 用途 |
|------|-------------|------|
| dev | 開発アカウント | 個人開発・デバッグ |
| staging | ステージングアカウント | 統合テスト・受け入れテスト |
| prod | 本番アカウント | 本番サービス |

小規模プロジェクトではシングルアカウント＋環境プレフィックスも許容。

### シークレット管理

**AWS Secrets Manager**を使用する：
- データベース接続情報
- API キー
- 外部サービスの認証情報

**AWS Systems Manager Parameter Store**を使用する：
- 環境固有の設定値（非機密）
- 機能フラグ

IaCコードからシークレットをハードコードしない。
CDKの場合は `cdk.SecretValue.secretsManager()` を使用する。

### ネットワーク構成

**VPC設計（サーバーレス構成の場合）：**

Lambda + API Gatewayの構成ではVPCは不要なケースが多い。
ただし以下の場合はVPCが必要：
- ElastiCache (Redis) への接続（VPC内リソース）
- RDSへの接続
- 社内ネットワークとの接続

VPCが必要な場合の構成：
```
VPC
├── Public Subnet (NAT Gateway)
├── Private Subnet (Lambda, ElastiCache)
└── Isolated Subnet (RDS, if applicable)
```

---

## デプロイ戦略

### サーバーレス（Lambda）のデプロイ

**AWS SAM / CDK によるデプロイ：**
- `cdk deploy --all` で全スタックをデプロイ
- Lambda のバージョニングとエイリアスを活用

**段階的デプロイ（CodeDeploy連携）：**
```
CodeDeploy設定:
  Type: LINEAR_10PERCENT_EVERY_1MINUTE
  # 10%ずつトラフィックを移行し、アラームで自動ロールバック
```

### コンテナ（ECS/Fargate）のデプロイ

**ブルー/グリーンデプロイ（CodeDeploy連携）：**
1. 新バージョンのタスクセットを起動
2. テストトラフィックで検証
3. 本番トラフィックを切り替え
4. 旧タスクセットを終了

**ロールバック：**
- CodeDeployの自動ロールバック（CloudWatchアラーム連動）
- 手動ロールバック：`aws deploy stop-deployment` + 旧バージョンへの切り戻し

---

## 観測可能性のAWSサービス

### メトリクスとアラーム：Amazon CloudWatch

**ダッシュボード構成：**
```python
# CDK でのダッシュボード定義例
dashboard = cloudwatch.Dashboard(self, "ServiceDashboard")
dashboard.add_widgets(
    cloudwatch.GraphWidget(
        title="API Latency",
        left=[api_latency_metric],
    ),
    cloudwatch.AlarmWidget(alarm=latency_alarm),
)
```

**アラーム設定のパターン：**

| NFRの種別 | CloudWatchメトリクス | 条件例 |
|-----------|-------------------|--------|
| レスポンスタイム | API Gateway Latency | P95 > 300ms が 5分間で3回 |
| エラー率 | Lambda Errors / Invocations | > 1% が 5分間継続 |
| スループット | API Gateway Count | < 期待値の50% が 10分間 |
| 可用性 | Lambda Errors | > 0 が 1分間で5回 |

**アラームアクション：**
- SNS Topic → Slack通知（Lambda経由）
- SNS Topic → PagerDuty / OpsGenie
- Auto Scaling / CodeDeploy自動ロールバック

### ログ：Amazon CloudWatch Logs

**構造化ログの設定：**
```python
import json
import logging

logger = logging.getLogger()

def handler(event, context):
    logger.info(json.dumps({
        "level": "INFO",
        "message": "Recommendation generated",
        "customer_id": customer_id,
        "algorithm": algorithm,
        "item_count": len(items),
        "latency_ms": latency,
        "request_id": context.aws_request_id,
    }))
```

**ログ保持期間：**
| 環境 | 保持期間 |
|------|---------|
| dev | 7日 |
| staging | 30日 |
| prod | 90日（コンプライアンスに応じて延長） |

**CloudWatch Logs Insights クエリ例：**
```
fields @timestamp, @message
| filter level = "ERROR"
| sort @timestamp desc
| limit 20
```

### トレース：AWS X-Ray

**Lambda関数の計装：**
```python
from aws_xray_sdk.core import patch_all
patch_all()  # boto3, requests等の呼び出しを自動計装
```

**サービスマップ：**
X-Rayサービスマップでユニット間の呼び出しチェーンを可視化。
レイテンシのボトルネック特定に使用。

---

## IaC実行手順

### CDKの場合

```bash
# 環境のブートストラップ（初回のみ）
cdk bootstrap aws://{ACCOUNT_ID}/{REGION}

# 差分確認
cdk diff --context env=staging

# ステージングデプロイ
cdk deploy --all --context env=staging --require-approval never

# 本番デプロイ（承認後）
cdk deploy --all --context env=prod --require-approval broadening
```

### CloudFormationの場合

```bash
# チェンジセット作成
aws cloudformation create-change-set \
  --stack-name {stack} \
  --template-body file://template.yaml \
  --change-set-name release-{version}

# チェンジセット確認
aws cloudformation describe-change-set --change-set-name release-{version}

# 実行（承認後）
aws cloudformation execute-change-set --change-set-name release-{version}
```

### Terraformの場合

```bash
# 初期化
terraform init -backend-config=env/staging.hcl

# プラン確認
terraform plan -var-file=env/staging.tfvars

# 適用（承認後）
terraform apply -var-file=env/prod.tfvars
```

---

## ロールバック手順

### Lambda（CDK/SAM）
```bash
# 前バージョンのエイリアスに戻す
aws lambda update-alias \
  --function-name {function} \
  --name live \
  --function-version {previous_version}
```

### CloudFormation/CDK
```bash
# 前回のデプロイにロールバック
aws cloudformation rollback-stack --stack-name {stack}
# または前バージョンのテンプレートで再デプロイ
cdk deploy --all --context env=prod  # 前バージョンのコードで
```

### DynamoDB（データロールバック）
- Point-in-Time Recovery (PITR) を有効化しておく
- 必要に応じて特定時点のテーブルを復元

---

## スモークテスト

### API疎通確認
```bash
# ヘルスチェック
curl -s -o /dev/null -w "%{http_code}" https://{api_endpoint}/health
# 期待値: 200

# 主要エンドポイント
curl -s https://{api_endpoint}/recommendations/{test_customer_id}
# 期待値: 200 + JSON レスポンス
```

### 自動スモークテスト（CodeBuild内）
```python
import requests

def test_health():
    r = requests.get(f"{API_ENDPOINT}/health")
    assert r.status_code == 200

def test_recommendation_endpoint():
    r = requests.get(f"{API_ENDPOINT}/recommendations/SMOKE-TEST-001")
    assert r.status_code == 200
    data = r.json()
    assert "recommendations" in data
    assert len(data["recommendations"]) >= 1
```
