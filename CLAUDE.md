# CLAUDE.md — aidlc-plugin

## Project Overview

AI-DLC (AI-Driven Development Lifecycle) の Claude Code プラグイン。
AI がソフトウェア開発ライフサイクル全体（構想→構築→リリース→運用）を主導する手法を、7つのスキルと11のサブエージェントで実装している。

## Structure

```
.claude-plugin/plugin.json   # プラグインマニフェスト (v0.1.0)
skills/                       # 7スキル (SKILL.md + references/)
  user-stories/               # S1: 意図→ユーザーストーリー
  unit-decomposition/         # S2: ストーリー→ユニット分解
  mockup/                     # S3: UIモックアップ (任意)
  build-bolt/                 # S4: ドメイン設計→実装→検証 (6ステップ)
  iac/                        # S5: IaCコード生成
  release/                    # S6: CI/CD・デプロイ
  operate/                    # S7: 運用・監視
agents/                       # 11サブエージェント (.md)
docs/                         # 設計ドキュメント
  aidlc-plugin-architecture.md    # マスターアーキテクチャ
  aidlc-interface-contract.md     # スキル間インターフェース仕様
  aidlc-subagent-specs.md         # サブエージェント入出力仕様
hooks/hooks.json              # Claude Code ライフサイクルフック
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

- スキル定義は `skills/<name>/SKILL.md` に記述
- 参照ファイルは `skills/<name>/references/` 配下に配置
- サブエージェント定義は `agents/<name>.md` に記述
- フックは `hooks/hooks.json` で定義 (PostToolUse, SubagentStop)
- ドキュメントは日本語で記述

## Working with This Plugin

- ビルド/テストスクリプトなし (全ファイル Markdown + JSON)
- プラグイン読み込み: `claude --plugin-dir ./aidlc-plugin`
- スキル・エージェントの編集時は `docs/` 内の仕様との整合性を確認すること
- build-bolt は最も複雑なスキル (内部6ステップ: ドメイン設計→論理設計→テスト生成→Red-Green-Refactor→インフラ実装→検証)
