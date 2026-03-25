---
name: iac
description: >
  AI-DLCにおけるIaC生成・管理スキル。
  全ボルト完了後に論理設計のサービスマッピングに基づきIaCコードを生成する。
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
model: sonnet
effort: high
---

# AI-DLC IaCスキル

## トリガー条件

以下の場合にこのスキルを使用する：
- ユーザーが「IaC」「インフラコード」「Terraform」「CDK」「CloudFormation」「デプロイメントコード」「インフラストラクチャ」と言及した場合
- aidlc-build-boltスキルで全ボルトが完了した後に使用する

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

**成果物登録・コミット:** IaCコードを manifest.md に登録し、prompts.md に記録してコミットする。
コミット: `aidlc(iac): step2 IaCコード生成`

### step3: 検証

IaCコードの静的検証（lint、セキュリティチェック）を実行する。

完了後、`aidlc:handoff-generator` エージェントで `handoffs/to_release.md` を生成。

**成果物登録・コミット:** 検証結果と引き継ぎファイルを manifest.md に登録し、
全成果物が manifest.md に漏れなく登録されていることを最終確認する。
prompts.md に記録してコミットする。
コミット: `aidlc(iac): step3 検証・引き継ぎ完了`

---

## 成果物の記録・コミット規約

各ステップで成果物を保存した際、以下を一連の流れで実行する:
1. **prompts.md 記録** — 実行内容の要約を `aidlc-docs/prompts.md` に追記する
2. **manifest.md 登録** — 保存したファイルを `aidlc-docs/manifest.md` に登録する
3. **コミット** — 成果物ファイル + manifest.md + prompts.md をまとめてコミットする

コミットメッセージ規約: `aidlc(iac): step{N} {概要}`
