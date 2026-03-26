# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-03-26

### Added
- フレーバー「ストーリーベース」を追加 — 軽量なコンポーネントモデルベースの設計アプローチ
- AI推薦型フレーバー選択 — プロジェクト特性を分析しAIが推薦、ユーザーが承認/変更
- ユニット分解 step5 にプレゼンテーション層チェックリストを追加
- 「UI統合ボルト」概念をボルト計画に導入（bolt-planning.md）
- ADR延期セクション（延期先ボルト・理由・リスク）を論理設計ガイドに追加
- build-bolt step0 に延期ADR読み込み、step2 に延期ADR解決手順を追加
- build-bolt step6-final に未解決ADR延期ガード（「要計画」残存時は中断）を追加
- build-bolt step6-final にE2Eブラウザ検証ステップを追加（UIプロジェクト限定）
- cross-review 観点カタログに `ADR_DEFERRAL_RESOLVED` を追加
- manifest.md の reportsセクションに e2e_verification_report エントリを追加
- to_iac.md 前提条件にE2E検証レポート要件を追加（UIプロジェクトの場合）
- `scripts/init.sh` — 冪等な初期セットアップスクリプト（フォルダ構造 + manifest.md テンプレート）
- user-stories step0 でスクリプト実行による初期セットアップ
- plugin-audit にステップ6「チェンジログ・CLAUDE.md の更新」を追加
- plugin-audit 監査チェックリストに CHANGELOG.md・CLAUDE.md セクションを追加

### Changed
- フレーバー選択肢を DDD/BDD/TDD → DDD/BDD/ストーリーベース に変更
- TDD を排他的フレーバーから全フレーバー共通の実装手法に格上げ
- decomposition-principles.md の「技術レイヤー分割」アンチパターンにUI統合計画に関する補足を追加
- 論理設計仕様の品質チェックリストにADR延期確認項目を追加
- plugin.json の keywords に "story-based" を追加

### Removed
- TDDフレーバー（全フレーバー共通の実装手法に統合）

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
