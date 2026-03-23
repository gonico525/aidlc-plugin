---
name: aidlc-plugin-audit
description: >
  AI-DLCプラグインの公式仕様準拠性を監査・改修するスキル。
  Claude Code Plugin/Skill/Agent の公式仕様と現在のプラグイン実装を照合し、
  差分の検出・改修計画・自動修正を一貫して実行する。
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch
model: opus
effort: max
---

# AI-DLC プラグイン監査スキル

## トリガー条件

以下の場合にこのスキルを使用する：
- ユーザーが「プラグインの監査」「公式仕様との差分」「プラグインの改善」「仕様準拠チェック」「プラグインのアップデート」「フロントマターの見直し」と言及した場合
- Claude Code のプラグイン仕様が更新された後に、既存プラグインの準拠性を確認したい文脈
- スキルやエージェントの追加・変更後に整合性を担保したい場合

## このスキルの目的

AI-DLC プラグインのメンテナンス品質を保つ。
Claude Code Plugin の公式仕様（plugin.json, SKILL.md フロントマター, エージェント .md フロントマター, hooks.json）と現在の実装を機械的に照合し、
不整合を検出して修正する。

**設計原則:**
- 公式仕様をまず調査し、「正解」を把握してから差分を検出する
- 変更は計画を立ててユーザーに承認を得てから実行する
- docs/ と実装ファイルの整合性も対象に含める

## 前提知識

Claude Code Plugin 公式仕様は `references/claude-code-plugin-spec.md` を参照。
プラグイン内部の設計規約は `CLAUDE.md` と `docs/aidlc-plugin-architecture.md` を参照。

---

## ワークフロー

### ステップ0：公式仕様の調査

最新の Claude Code Plugin 仕様を確認する。

1. **WebSearch** で Claude Code の公式ドキュメントを検索
   - `"Claude Code" plugin SKILL.md frontmatter specification`
   - `"Claude Code" plugin.json manifest fields`
   - `"Claude Code" agent .md frontmatter`
2. 取得した仕様を `references/claude-code-plugin-spec.md` に保存（既存なら更新）
3. 仕様のキーポイントをまとめる：
   - plugin.json の必須/任意フィールド
   - SKILL.md フロントマターの全フィールドと許容値
   - エージェント .md フロントマターの全フィールドと許容値
   - hooks.json の構造と変数

### ステップ1：現状スキャン

プラグインの全コンポーネントを読み取り、現状を把握する。

**スキャン対象:**

| カテゴリ | 対象ファイル | チェック項目 |
|---------|------------|------------|
| マニフェスト | `.claude-plugin/plugin.json` | version, 必須フィールド, コンポーネントパス宣言 |
| スキル | `skills/*/SKILL.md` (全件) | name, description, allowed-tools, model, effort |
| エージェント | `agents/*.md` (全件) | name, description, model, effort, maxTurns, tools, disallowedTools |
| フック | `hooks/hooks.json` | イベントタイプ, 変数参照, JSON構文 |
| ドキュメント | `docs/*.md` | バージョン参照, スキル/エージェント名の整合性 |
| CLAUDE.md | `CLAUDE.md` | バージョン, 構造記述の正確性 |

**スキャン手順:**
1. Glob で対象ファイルを列挙
2. 各ファイルのフロントマターを Read で抽出
3. 公式仕様と照合し、差分リストを作成

### ステップ2：差分レポートの生成

ステップ0の公式仕様とステップ1の現状を照合し、差分レポートを生成する。

**レポートフォーマット:**

```markdown
# プラグイン監査レポート

## サマリー
- 監査日: {YYYY-MM-DD}
- プラグインバージョン: {現在のversion}
- 公式仕様参照日: {仕様調査日}
- 不整合件数: {N}件（重大: {N}, 軽微: {N}）

## 不整合一覧

| # | カテゴリ | ファイル | 項目 | 現状 | 期待値 | 重大度 |
|---|---------|---------|------|------|--------|--------|
| 1 | {カテゴリ} | {ファイルパス} | {項目名} | {現在の値} | {公式仕様の値} | {重大/軽微} |

## 推奨アクション
{修正の優先順位付きリスト}
```

レポートをユーザーに提示し、修正方針の承認を得る。**[承認ゲート]**

### ステップ3：改修計画の策定

承認された差分に対して、具体的な改修計画を策定する。

1. 各不整合に対する修正内容を決定
2. ファイル間の依存関係を考慮した実行順序を決定
3. 並列実行可能なタスクを特定
4. 計画をユーザーに提示 **[承認ゲート]**

**計画の構造:**
```
Phase 1: コア設定 (並列可)
  - plugin.json の更新
  - hooks.json の修正

Phase 2: スキル/エージェント (並列可)
  - SKILL.md フロントマター修正 (全件)
  - agents/*.md フロントマター修正 (全件)

Phase 3: ドキュメント (Phase 2完了後)
  - docs/ の更新
  - CLAUDE.md の更新

Phase 4: 検証
  - 全ファイルの整合性確認
```

### ステップ4：改修実行

計画に従い、ファイルを修正する。

**実行ルール:**
- 各ファイルは Read → Edit のパターンで修正（まず読んでから編集）
- 独立した修正は並列で実行可能
- フロントマターの YAML 構文を破壊しないよう注意
- docs/ は実装ファイルの修正完了後に更新（整合性を保つため）

### ステップ5：検証

全修正が完了したら、以下を検証する。

1. **フロントマター構文チェック**
   - 全 SKILL.md と agents/*.md の YAML フロントマターがパース可能か
2. **命名規則の整合性**
   - Grep で docs/ 内のスキル名参照が統一されているか
3. **バージョンの整合性**
   - plugin.json, docs/, CLAUDE.md のバージョンが一致しているか
4. **hooks.json の JSON 構文チェック**
5. **plugin.json と実ファイルの整合性**
   - 宣言されたパスに実際のファイルが存在するか

検証結果をユーザーに報告する。

### ステップ6：コミット

全検証が通ったら、変更をコミットする。

1. `git status` で変更ファイルを確認
2. `git diff --stat` で変更量を確認
3. ユーザーにコミットメッセージを提案 **[承認ゲート]**
4. 承認後にコミット＆プッシュ

---

## 監査チェックリスト

以下は各コンポーネントの標準チェック項目。

### plugin.json
- [ ] `name`, `version`, `description` が設定されている
- [ ] `skills`, `agents`, `hooks` のパスが宣言されている
- [ ] `repository`, `license` 等のメタデータが設定されている

### SKILL.md フロントマター
- [ ] `name` に `aidlc-` プレフィックスが付いている
- [ ] `description` が 2-3 行以内に収まっている
- [ ] `allowed-tools` が設定されている
- [ ] `model` が `sonnet` または `opus` で設定されている
- [ ] `effort` が `medium`, `high`, `max` のいずれかで設定されている
- [ ] `## トリガー条件` セクションが本文に存在する

### agents/*.md フロントマター
- [ ] `name`, `description`, `model`, `effort`, `maxTurns` が設定されている
- [ ] `tools` が最小権限の原則に基づき設定されている
- [ ] `disallowedTools` が設定されている
- [ ] `model` が `sonnet` である（全エージェント共通）

### hooks.json
- [ ] JSON として構文的に有効
- [ ] イベントタイプが公式仕様に存在するものである
- [ ] 変数参照が公式仕様で定義されたものである

### docs/
- [ ] バージョン参照が plugin.json と一致
- [ ] スキル名が `aidlc-` プレフィックス付きで統一されている
- [ ] ステータスが最新の状態を反映している
