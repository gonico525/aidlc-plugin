# CLAUDE.md — aidlc-plugin

## Project Overview

AI-DLC (AI-Driven Development Lifecycle) の Claude Code プラグイン (v0.3.0)。
AI がソフトウェア開発ライフサイクル全体（構想→構築→リリース→運用）を主導する手法を、8つのスキルと11のサブエージェントで実装している。
公式 Claude Code プラグイン仕様に準拠。

## Structure

```
.claude-plugin/plugin.json   # プラグインマニフェスト (v0.3.0)
skills/                       # 8スキル (SKILL.md + references/)
  user-stories/               # S1: user-stories — 意図→ユーザーストーリー
  unit-decomposition/         # S2: unit-decomposition — ストーリー→ユニット分解
  mockup/                     # S3: mockup — UIモックアップ (任意)
  build-bolt/                 # S4: build-bolt — ドメイン設計→実装→検証 (6ステップ)
  iac/                        # S5: iac — IaCコード生成
  release/                    # S6: release — CI/CD・デプロイ
  operate/                    # S7: operate — 運用・監視
  plugin-audit/               # S8: plugin-audit — 公式仕様準拠性の監査・改修
agents/                       # 11サブエージェント (.md)
docs/                         # 設計ドキュメント
  aidlc-plugin-architecture.md    # マスターアーキテクチャ
  aidlc-interface-contract.md     # スキル間インターフェース仕様
  aidlc-subagent-specs.md         # サブエージェント入出力仕様
scripts/init.sh               # 初期セットアップスクリプト
hooks/hooks.json              # Claude Code ライフサイクルフック (現状は空のプレースホルダ)
.claude-plugin/marketplace.json  # マーケットプレイス定義 (配布用ハブ)
```

## Key Concepts

- **スキル** = 「誰がいつ話すか」。役割遷移とセッション境界を表す
- **サブエージェント** = 「コンテキスト分離」。純粋関数的な計算を隔離実行
- **manifest.md** = 全フェーズのアーティファクト単一情報源
- **ハンドオフファイル** = スキル間データ受け渡し (共通ヘッダ + スキル固有ペイロード)

## Development Phases (AI-DLC)

1. **構想 (Envision)**: user-stories → unit-decomposition → mockup(任意)
2. **構築 (Build)**: build-bolt (ボルト単位で反復) → iac
3. **リリース (Release)**: release
4. **運用 (Operate)**: operate

## Conventions

### 命名規則
- スキル name はフォルダ名と一致させる（例: `build-bolt`, `iac`）
- 呼び出しは `aidlc:{スキル名}` 形式（例: `aidlc:build-bolt`, `aidlc:user-stories`）
- エージェント名はプレフィックスなし（例: `code-generator`）

### ファイル配置
- スキル定義は `skills/<name>/SKILL.md` に記述
- 参照ファイルは `skills/<name>/references/` 配下に配置
- サブエージェント定義は `agents/<name>.md` に記述
- フックは `hooks/hooks.json` で定義 (現状は空。必要時に PostToolUse / SubagentStop 等を追加)
- ドキュメントは日本語で記述

### フロントマターフィールド

**スキル (SKILL.md):**
- `name` — スキル名 (フォルダ名と一致)
- `description` — 短い説明 (2-3行)。トリガー条件は本文の `## トリガー条件` セクションに記述
- `allowed-tools` — 使用可能ツール (カンマ区切り)
- `model` — 使用モデル (`sonnet` / `opus`)
- `effort` — 推論レベル (`medium` / `high` / `max`)

**サブエージェント (agents/*.md):**
- `name`, `description`, `model`, `effort`, `maxTurns` — 基本メタデータ
- `tools` — 許可ツール (最小権限の原則)
- `disallowedTools` — 拒否ツール

## Working with This Plugin

- ビルド/テストスクリプトなし (全ファイル Markdown + JSON)
- プラグイン読み込み: `claude --plugin-dir ./aidlc-plugin`
- スキル・エージェントの編集時は `docs/` 内の仕様との整合性を確認すること
- build-bolt は最も複雑なスキル (model: opus, effort: max, 内部6ステップ)
- 全サブエージェントは model: sonnet を使用
