# AI-DLC プラグインアーキテクチャ設計

## ステータス: v0.2.0 実装完了（Claude Code Plugin形式）

---

## 1. 設計原則

### 1.1 スキルとサブエージェントの境界

AI-DLCのプラグインシステムは **スキル** と **サブエージェント** の2層で構成する。
両者の責務は明確に異なる。

| 観点 | スキル (Skill) | サブエージェント (Sub-agent) |
|------|---------------|---------------------------|
| **責務** | 人間との対話を司る | 隔離されたコンテキストで実行する |
| **会話コンテキスト** | 全体が必要 | 最小限の焦点化コンテキストのみ |
| **人間の関与** | 承認ゲート、意思決定の委譲 | なし（入力→出力の自動実行） |
| **呼び出し** | ユーザーまたはワークフローがトリガー | スキル内のステップから呼び出される |

### 1.2 スキル分割の基準（改訂版）

スキルを分ける理由は **2つだけ**:

1. **ペルソナの切替** — 対話相手の役割が変わるとき
   - 例: 構想フェーズ（PO + チーム）→ 構築フェーズ（開発者）
2. **セッションの自然な切れ目** — 「今日はここまで」が自然に発生する単位
   - 例: ストーリー詳細化完了 → 翌日ユニット分解

**以下はスキル分割の理由にならない:**
- 承認ゲートの存在（スキル内のステップで制御すれば十分）
- 関心事の違い（サブエージェントによるコンテキスト隔離で対応）
- 技術的な入出力の違い（スキル内で切り替え可能）

### 1.3 サブエージェントの役割

コンテキスト隔離が必要な処理をサブエージェントに委譲する。
サブエージェントは「明確な入力 → 明確な出力」の純粋関数的な実行単位。

サブエージェント化の基準:
- 会話履歴が不要で、成果物ファイルだけで実行可能
- コンテキストウィンドウの節約が効果的（大量コード生成など）
- 複数のスキル/フェーズから再利用される処理

---

## 2. 全体フロー（改訂版）

### 2.1 スキル一覧（8個）

```
構想フェーズ (envision)
├── S1: aidlc-user-stories               — 意図→ストーリー詳細化 [PO + チーム]
├── S2: aidlc-unit-decomposition     — ストーリー→ユニット分解 [PO + アーキテクト]
└── S3: aidlc-mockup                           — UIモックアップ作成 [任意]

構築フェーズ (build)
├── S4: aidlc-build-bolt                   — 1ボルトの全工程 [開発者] ※ボルト単位で反復
└── S5: aidlc-iac                                 — IaC生成・管理 [開発者/SRE] ※全ボルト完了後

リリース・運用フェーズ (release / operate)
├── S6: aidlc-release                         — CI/CD・環境構築・デプロイ [SRE]
└── S7: aidlc-operate                         — 観測・インシデント対応 [開発者/SRE]

メタ（プラグイン自体の保守）
└── S8: aidlc-plugin-audit               — 公式仕様準拠性の監査・改修 [開発者]
```

### 2.2 サブエージェント一覧（11個）

```
汎用（全フェーズ共通）
├── A1: cross-review         — 横断整合性チェック（レビュー観点をパラメータ化）
└── A2: handoff-generator    — フェーズ間引き継ぎ文書の生成

構想フェーズ用
└── A3: story-quality-check  — INVEST基準によるストーリー品質検証

構築フェーズ用 (build-bolt内部)
├── A4: test-generator       — ドメインモデル+受け入れ基準→テストコード生成
├── A5: code-generator       — 承認済みテストを通すドメインレイヤー実装
├── A6: refactorer           — コード品質改善（重複排除、パターン適用）
├── A7: infra-impl           — 統合テスト生成+インフラレイヤー実装
└── A8: verification-report  — テスト一括実行+検証レポート生成

IaCスキル用
└── A9: iac-generator        — 論理設計→IaCコード生成

リリース・運用フェーズ用
├── A10: pipeline-generator  — CI/CDパイプライン定義の生成
└── A11: monitoring-setup    — 観測可能性セットアップ（アラーム、ダッシュボード）
```

### 2.3 拡張性の実現方法

AI-DLC独自のフック機構は設けない。拡張性は以下の2層で実現する。

**ドメイン層の拡張 — A1:cross-review のレビュー観点追加**
組織固有のチェック（コンプライアンス、アーキテクチャ適合性等）は、
A1:cross-reviewのレビュー観点カタログに観点を追加することで実現する。
組織固有のルール定義ファイルはスキルの references/ に配置する。

**インフラ層の拡張 — Claude Code ライフサイクルフック**
Slack通知、監査ログ、コードフォーマッター、ライセンスヘッダー挿入等の
自動化は、Claude Codeのフック機構（PreToolUse / PostToolUse / Stop 等）で
実現する。プロジェクトルートの hooks/ ディレクトリに配置する。

---

## 3. build-bolt スキルの内部構造

build-boltは構築フェーズの中核スキル。1ボルトの全工程を1つの連続セッションで実行する。
承認ゲートはスキル内のステップとして存在し、重い処理はサブエージェントに委譲する。

### 3.1 ステップとサブエージェント呼び出し

```
build-bolt スキル
│
├── step0: 入力読み込み・ボルト対象の決定
│
├── step1: ドメイン設計
│   └── AIが提案 → 人間が承認 [承認ゲート]
│
├── step2: 論理設計
│   ├── AIが提案 → 人間が承認 [承認ゲート]
│   ├── ADR作成
│   └── ← A1: cross-review 呼び出し（設計整合性チェック）
│
├── step3: テスト契約
│   ├── ← A4: test-generator 呼び出し（テストコード生成）
│   └── 生成されたテストを人間が承認 [承認ゲート ※最重要]
│
├── step4: ドメインレイヤー実装 (Red → Green → Refactor)
│   ├── テスト実行 → 全件失敗確認 (Red)
│   ├── ← A5: code-generator 呼び出し
│   ├── テスト実行 → 全件パス確認 (Green)
│   ├── ← A6: refactorer 呼び出し
│   ├── テスト実行 → リグレッションなし確認
│   └── ※人間の介入は原則不要（テストが契約）
│
├── step5: インフラレイヤー実装
│   ├── ← A7: infra-impl 呼び出し（統合テスト生成含む）
│   ├── 統合テストを人間が承認 [承認ゲート]
│   └── Red → Green サイクル（step4と同様）
│
├── step6: 横断レビュー・最終検証
│   ├── ← A8: verification-report 呼び出し
│   └── ← A1: cross-review 呼び出し（コード-設計整合性チェック）
│
└── → 次のボルトがあればstep0に戻る
```

### 3.2 承認ゲートの一覧

| ステップ | 承認対象 | 重要度 | 承認者 |
|---------|---------|--------|-------|
| step1 | ドメインモデル | 高 | 開発者 |
| step2 | 論理設計・ADR | 高 | 開発者 |
| step3 | テストコード（＝正しさの契約） | **最高** | 開発者 |
| step4 | なし（テストが契約として機能） | — | — |
| step5 | 統合テスト | 中 | 開発者 |
| step6 | 検証レポート確認 | 中 | 開発者 |

---

## 4. 現行スキルからの変更マッピング

| 現行スキル | 改訂後 | 変更内容 |
|-----------|--------|---------|
| aidlc-user-stories | S1: aidlc-user-stories | 変更なし |
| aidlc-unit-decomposition | S2: aidlc-unit-decomposition | 変更なし |
| aidlc-mockup | S3: aidlc-mockup | 変更なし |
| aidlc-design | S4: aidlc-build-bolt の step1-2 | build-boltに統合 |
| aidlc-implementation | S4: aidlc-build-bolt の step3-6 | build-boltに統合、サブエージェント化 |
| aidlc-release | S6: aidlc-release | 変更なし |
| （なし） | S5: aidlc-iac | 新規独立スキル（implementationから分離） |
| （なし） | S7: aidlc-operate | 新規スキル（運用フェーズ） |

---

## 5. 未決定事項（次の議論対象）

### 5.1 サブエージェントの呼び出し方法 → ✅ 設計完了
- 詳細は `aidlc-subagent-specs.md` を参照
- 共通呼び出しパターン: directive + inputs + outputs
- 共通結果: status (success/failure/needs_human) + outputs + summary + issues
- エラーハンドリング: failure→再実行判断、needs_human→人間に委譲、タイムアウト→部分確認

### 5.2 フック機構の詳細 → ✅ 解消（廃止）
- AI-DLC独自のワークフローフックは不要と判断
- ドメイン層の拡張: A1:cross-reviewのレビュー観点カタログに組織固有観点を追加
- インフラ層の拡張: Claude Codeライフサイクルフック（hooks/ディレクトリ）で対応
- `aidlc-hook-specs.md` は廃止

### 5.3 スキル間のインターフェース契約 → ✅ 設計完了
- 詳細は `aidlc-interface-contract.md` を参照
- manifest.md（全成果物の一元台帳）+ 共通ヘッダー付きハンドオフの2層構造
- スキルが実装すべき3つのインターフェース: on_start / on_artifact / on_complete

### 5.4 cross-reviewサブエージェントの設計 → ✅ 設計完了
- 詳細は `aidlc-subagent-specs.md` セクション2.6 を参照
- レビュー観点カタログ（11観点）をパラメータ化
- fix_mode (auto_fix / report_only) で自動修正と報告のみを切替

---

## 6. Claude Code Plugin 実装

設計を Claude Code Plugin 形式 (`aidlc-plugin/`) で実装した。

### 6.1 ディレクトリ構造

```
aidlc-plugin/
├── .claude-plugin/plugin.json    # プラグインマニフェスト
├── skills/                       # スキル (7個)
│   ├── user-stories/SKILL.md     # 構想: ストーリー詳細化
│   ├── unit-decomposition/SKILL.md # 構想: ユニット分解
│   ├── mockup/SKILL.md           # 構想: UIモックアップ (任意)
│   ├── build-bolt/SKILL.md       # 構築: 1ボルトの全工程 ★新規統合
│   ├── iac/SKILL.md              # 構築: IaC生成 ★新規分離
│   ├── release/SKILL.md          # リリース
│   └── operate/SKILL.md          # 運用 ★新規
├── agents/                       # エージェント (11個) ★全て新規
│   ├── cross-review.md           # 横断整合性チェック (全フェーズ共通)
│   ├── handoff-generator.md      # ハンドオフ生成 (全フェーズ共通)
│   ├── story-quality-check.md    # INVEST基準検証
│   ├── test-generator.md         # テストコード生成
│   ├── code-generator.md         # ドメインレイヤー実装
│   ├── refactorer.md             # コード品質改善
│   ├── infra-impl.md             # インフラレイヤー実装
│   ├── verification-report.md    # 検証レポート生成
│   ├── iac-generator.md          # IaCコード生成
│   ├── pipeline-generator.md     # CI/CDパイプライン生成
│   └── monitoring-setup.md       # モニタリングセットアップ
└── hooks/hooks.json              # Claude Codeライフサイクルフック
```

### 6.2 旧スキルからの移行

| 旧スキル | 新コンポーネント | 変更 |
|---------|---------------|------|
| aidlc-user-stories | S1: aidlc-user-stories | エージェント参照に更新 |
| aidlc-unit-decomposition | S2: aidlc-unit-decomposition | エージェント参照に更新 |
| aidlc-mockup | S3: aidlc-mockup | 参照先を更新 |
| aidlc-design | S4: aidlc-build-bolt (step1-2) | build-boltに統合 |
| aidlc-implementation | S4: aidlc-build-bolt (step3-6) | build-boltに統合 |
| aidlc-release | S6: aidlc-release | ハンドオフパスを更新 |
| (なし) | S5: aidlc-iac | 新規 |
| (なし) | S7: aidlc-operate | 新規 |
| (なし) | agents/* (11個) | 全て新規 |

### 6.3 インストール方法

```bash
# ローカル開発での利用
claude --plugin-dir ./aidlc-plugin

# プロジェクトスコープでの配布（チーム共有）
# marketplace経由、または settings.json の enabledPlugins に追加
```

---

## 変更履歴

| 日付 | 内容 |
|------|------|
| 2026-03-23 | 初版作成。スキル/サブエージェント/フックの全体設計を議論・整理 |
| 2026-03-23 | インターフェース契約仕様を追加（aidlc-interface-contract.md） |
| 2026-03-23 | サブエージェント入出力仕様を追加（aidlc-subagent-specs.md） |
| 2026-03-23 | ワークフローフックを廃止。拡張性はcross-review観点追加+Claude Codeフックで実現 |
| 2026-03-23 | Claude Code Plugin形式で実装 (aidlc-plugin/) |
