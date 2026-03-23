# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-03-23

### Added
- S8: plugin-audit スキル — 公式仕様準拠性の監査・改修ワークフロー
- 全11エージェントに `tools` / `disallowedTools` フィールド（最小権限の原則）
- plugin.json に `skills`, `agents`, `hooks` コンポーネントパス宣言
- plugin.json に `license`, `repository`, `homepage` メタデータ
- `skills/iac/references/iac-best-practices.md` — IaCベストプラクティス
- `skills/operate/references/operations-guide.md` — 運用ガイド
- `skills/plugin-audit/references/claude-code-plugin-spec.md` — 公式仕様リファレンス
- docs 全3ファイルにツール制限セクション追加
- A2: handoff-generator の詳細仕様を `aidlc-subagent-specs.md` に追加

### Changed
- スキル name からプレフィックス `aidlc-` を除去（フォルダ名と統一）
  - 呼び出しが `aidlc:build-bolt` のように簡潔に
- 全7スキルのフロントマター強化（allowed-tools, model, effort 追加）
- build-bolt: `model: opus`, `effort: max` に設定
- description を2-3行に短縮、トリガー条件は本文 `## トリガー条件` セクションに移動
- docs/ のステータスを `v0.2.0 確定` に更新
- docs/ 内のスキルID参照を統一名称に更新

## [0.1.0] - 2026-03-23

### Added
- 初版リリース
- 7スキル: user-stories, unit-decomposition, mockup, build-bolt, iac, release, operate
- 11サブエージェント: cross-review, handoff-generator, story-quality-check, test-generator, code-generator, refactorer, infra-impl, verification-report, iac-generator, pipeline-generator, monitoring-setup
- Claude Code Plugin 形式 (plugin.json, SKILL.md, agents/*.md, hooks.json)
- 設計ドキュメント: アーキテクチャ設計、インターフェース契約仕様、サブエージェント入出力仕様
