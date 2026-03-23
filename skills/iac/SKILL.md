---
name: iac
description: >
  AI-DLCにおけるIaC（Infrastructure as Code）生成・管理スキル。
  全ボルト完了後に実行し、論理設計のサービスマッピングに基づいて
  IaCコードを生成する。build-boltスキルとは別セッションで実行する。
  このスキルは以下の場合にトリガーすべき：ユーザーが「IaC」「インフラコード」
  「Terraform」「CDK」「CloudFormation」「デプロイメントコード」
  「インフラストラクチャ」と言及した場合。
  build-boltスキルで全ボルトが完了した後に使用する。
---

# AI-DLC IaCスキル

## このスキルの目的

構築フェーズで生成されたテスト済みコードに対して、
IaC（Infrastructure as Code）を生成・管理する。

build-boltとは別スキルとして独立している理由:
- ペルソナが異なる可能性がある（SRE）
- 全ボルト完了後にまとめて実行する別セッション
- 必要なコンテキストがドメイン実装とは異なる

## 入力

**必須入力:**
- `aidlc-docs/handoffs/to_iac.md` — サービスマッピング、テスト結果
- `aidlc-docs/manifest.md` — 全成果物の台帳

## ワークフロー

### step0: 入力読み込み

1. `manifest.md` を読み込む
2. `handoffs/to_iac.md` を読み込む
3. 全ボルトのテスト結果が全件パスであることを確認
4. クラウドプロバイダーとIaCツールを確認

### step1: IaC生成計画

AIが以下を提案し、開発者/SREが承認する:
- IaCツール（CDK / CloudFormation / Terraform）
- デプロイメント戦略
- 環境構成（dev / staging / prod）

### step2: IaCコード生成

`aidlc:iac-generator` エージェントを呼び出し、IaCコードを生成する。

生成されたコードを開発者/SREに提示しレビューを依頼する。
**[承認ゲート]** IaCコードが承認されるまで次のステップに進まない。

### step3: 検証

IaCコードの静的検証（lint、セキュリティチェック）を実行し、
結果をmanifest.mdに登録する。

完了後、`aidlc:handoff-generator` エージェントで `handoffs/to_release.md` を生成。
