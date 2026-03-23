# IaC ベストプラクティスガイド

## IaCツール選定基準

| 基準 | AWS CDK | CloudFormation | Terraform |
|------|---------|---------------|-----------|
| 言語 | TypeScript/Python/Java等 | YAML/JSON | HCL |
| 抽象度 | 高（コンストラクト） | 低（リソース直接） | 中（モジュール） |
| マルチクラウド | AWS専用 | AWS専用 | マルチクラウド対応 |
| 状態管理 | CloudFormation経由 | スタック内蔵 | 外部Stateファイル |
| テスト容易性 | 高（ユニットテスト可） | 低 | 中（plan出力検証） |
| 学習コスト | 中（プログラミング必要） | 低 | 中 |

**選定の指針:**
- AWS単独 + 開発者チーム → **CDK** 推奨
- AWS単独 + インフラチーム → **CloudFormation** 推奨
- マルチクラウド or 既存Terraform資産あり → **Terraform** 推奨

## 共通ベストプラクティス

### 環境分離

- 環境ごとにパラメータファイル（`dev.json`, `staging.json`, `prod.json`）を分離
- ハードコーディングを避け、環境変数またはパラメータストアで設定を注入
- 環境間で同一テンプレート/コードを使い、パラメータのみ変更する

### シークレット管理

- シークレットをIaCコードに直接記述しない
- AWS Secrets Manager / Parameter Store（SecureString）を使用
- Terraform の場合は `sensitive = true` フラグを活用
- CDK の場合は `SecretValue.secretsManager()` を使用

### モジュールパターン

- 再利用可能な単位でモジュール/コンストラクトを分割
- モジュールの入力（パラメータ）と出力（エクスポート）を明確に定義
- ネスト深度は3階層以内に抑える
- 環境固有ロジックはモジュール外（呼び出し側）に置く

### Lint・セキュリティスキャン

| ツール | 対象 | チェック内容 |
|--------|------|-------------|
| `cfn-lint` | CloudFormation | テンプレートの構文・ベストプラクティス |
| `cdk synth` + `cdk diff` | CDK | 合成確認・差分確認 |
| `terraform validate` + `terraform plan` | Terraform | 構文・実行計画 |
| `checkov` / `tfsec` | 全般 | セキュリティポリシー違反の検出 |
| `cfn-nag` | CloudFormation | セキュリティ特化の静的解析 |

### ドリフト検出

- 手動変更によるドリフトを定期的に検出する仕組みを導入
- CloudFormation: `aws cloudformation detect-stack-drift`
- Terraform: `terraform plan` の差分で検出
- ドリフトが検出された場合はIaCコードに反映し、手動変更を巻き取る

### タグ付け戦略

全リソースに以下のタグを付与する：

| タグキー | 値の例 | 用途 |
|---------|--------|------|
| `Project` | `{プロジェクト名}` | コスト配分・リソース識別 |
| `Environment` | `dev/staging/prod` | 環境識別 |
| `ManagedBy` | `aidlc-iac` | IaC管理であることの明示 |
| `Unit` | `{ユニット名}` | AI-DLCユニット単位のトレーサビリティ |
