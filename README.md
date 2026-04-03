# AI-DLC Plugin for Claude Code

> AI-Driven Development Lifecycle — AI がソフトウェア開発ライフサイクル全体を主導する Claude Code プラグイン

[![Version](https://img.shields.io/badge/version-0.3.0-blue)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

## 概要

AI-DLC (AI-Driven Development Lifecycle) は、ソフトウェア開発の全フェーズ（構想→構築→リリース→運用）を AI が主導する手法です。本プラグインは **8 つのスキル**と **11 のサブエージェント**でこの手法を実装し、Claude Code の公式プラグイン仕様に準拠しています。

## 開発フェーズ

```
構想 (Envision)          構築 (Build)           リリース (Release)    運用 (Operate)
┌─────────────────┐    ┌─────────────────┐    ┌──────────────┐    ┌──────────────┐
│ user-stories     │───▶│ build-bolt      │───▶│ release      │───▶│ operate      │
│ unit-decomposition│   │ (ボルト単位で反復) │    │              │    │              │
│ mockup (任意)    │    │ iac             │    │              │    │              │
└─────────────────┘    └─────────────────┘    └──────────────┘    └──────────────┘
```

## スキル一覧

| スキル | 呼び出し | 説明 | モデル |
|--------|----------|------|--------|
| **user-stories** | `aidlc:user-stories` | 高レベルの意図からユーザーストーリー・受け入れ基準・NFR・リスクを生成 | sonnet |
| **unit-decomposition** | `aidlc:unit-decomposition` | ストーリーを独立構築可能なユニットにグループ化し、ボルト計画を策定 | sonnet |
| **mockup** | `aidlc:mockup` | ストーリーと受け入れ基準から UI モックアップ・画面遷移図を生成（任意） | sonnet |
| **build-bolt** | `aidlc:build-bolt` | ドメイン設計→論理設計→テスト→実装→検証を 1 セッションで実行 | opus |
| **iac** | `aidlc:iac` | 論理設計のサービスマッピングに基づき IaC コードを生成 | sonnet |
| **release** | `aidlc:release` | CI/CD パイプライン構築・デプロイメント・観測可能性設定 | sonnet |
| **operate** | `aidlc:operate` | デプロイ済みシステムの観測・異常検知・インシデント対応 | sonnet |
| **plugin-audit** | `aidlc:plugin-audit` | プラグインの公式仕様準拠性を監査・改修 | opus |

## サブエージェント一覧

| エージェント | 説明 |
|-------------|------|
| **cross-review** | 複数成果物間の不整合を検出（全フェーズから呼び出し可能） |
| **handoff-generator** | フェーズ間の引き継ぎ文書を生成 |
| **story-quality-check** | ストーリーが INVEST 基準を満たすか検証 |
| **test-generator** | ドメインモデルと受け入れ基準からテストコードを生成 |
| **code-generator** | 承認済みテストを通す実装コードを生成 |
| **refactorer** | Green 状態のコード品質を改善（テスト変更不可） |
| **infra-impl** | インフラストラクチャレイヤーの実装と統合テストを生成 |
| **verification-report** | 全テスト一括実行と検証レポートを生成 |
| **iac-generator** | サービスマッピングに基づき IaC コードを生成 |
| **pipeline-generator** | CI/CD パイプライン定義を生成 |
| **monitoring-setup** | 観測可能性のセットアップ（ダッシュボード・アラーム・ランブック） |

## セットアップ

### 前提条件

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) がインストール済みであること

### インストール

```bash
# リポジトリをクローン
git clone https://github.com/gonico525/aidlc-plugin.git

# プラグインを指定して Claude Code を起動
claude --plugin-dir ./aidlc-plugin
```

### プロジェクト初期化

最初のスキル (`aidlc:user-stories`) を実行すると、`scripts/init.sh` が自動的にプロジェクト構造を作成します。

```
aidlc-docs/
├── plans/
├── requirements/
├── story-artifacts/
├── design-artifacts/
│   ├── domain-models/
│   ├── logical-designs/
│   ├── adrs/
│   └── units/
├── handoffs/
├── reports/
├── manifest.md          # 全成果物台帳
└── prompts.md           # AI-DLC 指示記録
```

## 使い方

### 基本的なワークフロー

1. **構想フェーズ** — プロジェクトのアイデアや要件を伝えてスキルを順に実行

   ```
   aidlc:user-stories → aidlc:unit-decomposition → aidlc:mockup (任意)
   ```

2. **構築フェーズ** — ボルト（構築単位）ごとに設計・実装・検証を反復

   ```
   aidlc:build-bolt (ボルトごとに繰り返し) → aidlc:iac
   ```

3. **リリースフェーズ** — CI/CD パイプラインの構築とデプロイ

   ```
   aidlc:release
   ```

4. **運用フェーズ** — 監視・インシデント対応

   ```
   aidlc:operate
   ```

### データの受け渡し

スキル間のデータは **manifest.md**（全成果物の単一情報源）と**ハンドオフファイル**（スキル間の引き継ぎ文書）で受け渡されます。

## プロジェクト構造

```
.claude-plugin/plugin.json    # プラグインマニフェスト
skills/                        # 8 スキル
  <name>/SKILL.md             #   スキル定義
  <name>/references/          #   参照ファイル
agents/                        # 11 サブエージェント (.md)
docs/                          # 設計ドキュメント
  aidlc-plugin-architecture.md #   マスターアーキテクチャ
  aidlc-interface-contract.md  #   スキル間インターフェース仕様
  aidlc-subagent-specs.md      #   サブエージェント入出力仕様
scripts/init.sh                # 初期セットアップスクリプト
hooks/hooks.json               # ライフサイクルフック
```

## 主要コンセプト

| 概念 | 説明 |
|------|------|
| **スキル** | 「誰がいつ話すか」— 役割遷移とセッション境界 |
| **サブエージェント** | 「コンテキスト分離」— 純粋関数的な計算を隔離実行 |
| **manifest.md** | 全フェーズのアーティファクト単一情報源 |
| **ハンドオフファイル** | スキル間データ受け渡し（共通ヘッダ + スキル固有ペイロード） |
| **ボルト** | 構築の最小反復単位（時間〜日単位で完了可能） |

## ライセンス

[MIT](./LICENSE)
