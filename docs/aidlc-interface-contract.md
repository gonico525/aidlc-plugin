# AI-DLC インターフェース契約仕様

## ステータス: v0.2.0 確定

---

## 1. 全体構造

スキル間の情報受け渡しは **マニフェスト** と **ハンドオフ** の2層で構成する。

```
aidlc-docs/
├── manifest.md              ← 全成果物の一元台帳（全スキルが追記）
├── handoffs/                ← スキル間引き継ぎ
│   ├── to_units.md          (S1 → S2)
│   ├── to_build.md          (S2 → S4)
│   ├── to_iac.md            (S4 → S5)
│   ├── to_release.md        (S5 → S6)
│   └── to_operate.md        (S6 → S7)
├── plans/
├── requirements/
├── story-artifacts/
├── design-artifacts/
├── reports/
└── prompts.md
```

**責務の分離:**
- **manifest.md** — 「何が存在するか」を管理する。全成果物のパス・ステータス・生成元を記録。
- **handoff** — 「次のスキルに何を伝えるか」に集中する。判断・方針・コンテキストを伝達。

---

## 2. マニフェスト仕様 (manifest.md)

### 2.1 構造

```markdown
# AI-DLC マニフェスト

## メタ
- 意図: {高レベルの意図を1文で}
- フレーバー: {DDD / BDD / TDD}
- 開発種別: {グリーンフィールド / ブラウンフィールド}
- 作成日: {YYYY-MM-DD}
- 最終更新: {YYYY-MM-DD}

## 成果物台帳

### requirements（要件）
| ID | ファイル | 生成元 | ステータス | 最終更新 |
|----|---------|--------|----------|---------|
| REQ-001 | requirements/nfr_definition.md | S1:user-stories | 確定 | YYYY-MM-DD |
| REQ-002 | requirements/risk_description.md | S1:user-stories | 確定 | YYYY-MM-DD |
| REQ-003 | requirements/business_metrics.md | S1:user-stories | 確定 | YYYY-MM-DD |
| REQ-004 | requirements/ubiquitous_language.md | S1:user-stories | 確定 | YYYY-MM-DD |

### stories（ストーリー）
| ID | ファイル | 生成元 | ステータス | 最終更新 |
|----|---------|--------|----------|---------|
| STR-001 | story-artifacts/{領域名}_stories.md | S1:user-stories | 確定 | YYYY-MM-DD |

### units（ユニット）
| ID | ファイル | 生成元 | ステータス | 最終更新 |
|----|---------|--------|----------|---------|
| UNT-001 | design-artifacts/units/{ユニット名}.md | S2:unit-decomposition | 確定 | YYYY-MM-DD |

### designs（設計）
| ID | ファイル | 生成元 | ステータス | 最終更新 |
|----|---------|--------|----------|---------|
| DSG-001 | design-artifacts/domain-models/{ユニット名}_domain_model.md | S4:build-bolt | 確定 | YYYY-MM-DD |
| DSG-002 | design-artifacts/logical-designs/{ユニット名}_logical_design.md | S4:build-bolt | 確定 | YYYY-MM-DD |
| DSG-003 | design-artifacts/adrs/adr_{番号}_{タイトル}.md | S4:build-bolt | 承認 | YYYY-MM-DD |

### code（コード）
| ID | ファイル/ディレクトリ | 生成元 | ステータス | 最終更新 |
|----|-------------------|--------|----------|---------|
| COD-001 | {project}/src/domain/ | S4:build-bolt | テスト済み | YYYY-MM-DD |
| COD-002 | {project}/src/infrastructure/ | S4:build-bolt | テスト済み | YYYY-MM-DD |
| COD-003 | {project}/tests/ | S4:build-bolt | パス | YYYY-MM-DD |
| COD-004 | {project}/iac/ | S5:iac | 生成済み | YYYY-MM-DD |

### reports（レポート）
| ID | ファイル | 生成元 | ステータス | 最終更新 |
|----|---------|--------|----------|---------|
| RPT-001 | reports/cross_review_report.md | A1:cross-review | 完了 | YYYY-MM-DD |
| RPT-002 | reports/verification_report_{ボルト名}.md | A8:verification-report | 完了 | YYYY-MM-DD |

### plans（計画）
| ID | ファイル | 生成元 | ステータス | 最終更新 |
|----|---------|--------|----------|---------|
| PLN-001 | plans/user_stories_plan.md | S1:user-stories | 完了 | YYYY-MM-DD |
| PLN-002 | plans/bolt_schedule.md | S2:unit-decomposition | 確定 | YYYY-MM-DD |
```

### 2.2 運用ルール

- **追記のみ:** 各スキルは自分が生成した成果物の行を追加する。他スキルの行は変更しない。
- **ステータス遷移:** `下書き → 確定 → 修正中 → 確定`（サイクル可能）
- **生成元の記録:** `S{N}:{スキル名}` または `A{N}:{サブエージェント名}` で記録。
- **スキルの起動時:** manifest.md の存在確認から始める。なければ作成。あれば読み込み。

---

## 3. ハンドオフ共通ヘッダー仕様

全ハンドオフファイルは以下の共通ヘッダーで始まる。

```markdown
---
type: handoff
from: {生成元スキルID — 例: S1:user-stories}
to: {宛先スキルID — 例: S2:unit-decomposition}
created: {YYYY-MM-DD HH:MM}
status: {ready / blocked}
blocked_reason: {statusがblockedの場合のみ。例: "NFR定義が未完了"}
manifest: aidlc-docs/manifest.md
prerequisites:
  - {前提条件1 — 例: "manifest内のSTR-*が全てステータス'確定'であること"}
  - {前提条件2}
---
```

### 3.1 共通ヘッダーのフィールド定義

| フィールド | 必須 | 説明 |
|-----------|------|------|
| type | ○ | 常に `handoff` |
| from | ○ | 生成元スキルID |
| to | ○ | 宛先スキルID |
| created | ○ | 作成タイムスタンプ |
| status | ○ | `ready`（次スキル実行可能）/ `blocked`（前提条件未充足） |
| blocked_reason | △ | status=blocked の場合のみ |
| manifest | ○ | マニフェストファイルのパス |
| prerequisites | ○ | 宛先スキルが実行可能になるための前提条件リスト |

### 3.2 前提条件の記述ルール

前提条件は人間が読んで判断できる自然言語で記述する。
スキルはハンドオフ読み込み時に前提条件を表示し、問題があればユーザーに報告する。

例:
```yaml
prerequisites:
  - "manifest内のSTR-*が全てステータス'確定'であること"
  - "requirements/nfr_definition.md が存在すること"
  - "reports/cross_review_report.md の不整合がゼロであること"
```

---

## 4. スキル固有ペイロード仕様

共通ヘッダーの後にスキル固有のペイロードが続く。
以下に各ハンドオフのペイロードを定義する。

### 4.1 to_units.md (S1 → S2)

```markdown
# ペイロード

## 意図サマリー
{明確化済みの意図を1〜2文で}

## ストーリー概要
| ID | タイトル | 領域 | 優先度 | 複雑度 | 依存関係 |
|----|----------|------|--------|--------|----------|
| US-XXX | {タイトル} | {機能領域} | {高/中/低} | {S/M/L} | {他ストーリーIDまたは「なし」} |

## ストーリー間の依存関係マップ
{ストーリー間の依存・順序関係の要約}

## 横断レビュー結果サマリー
{不整合ゼロ / 残課題があれば概要}
```

### 4.2 to_build.md (S2 → S4)

```markdown
# ペイロード

## ユニット一覧
| ユニット | ストーリー数 | ボルト数 | 並行可否 | 想定期間 |
|----------|------------|---------|---------|---------|
| Unit-{N}: {名前} | {N} | {N} | {はい/いいえ} | {期間} |

## 推奨構築順序
{依存関係とビジネス優先度に基づく構築順序}

## クリティカルパス
{全体の最短完了経路}

## ブラウンフィールド情報
{該当する場合: 既存コードベースのパス、対象範囲}

## 横断レビュー結果サマリー
{不整合ゼロ / 残課題があれば概要}
```

### 4.3 to_iac.md (S4 → S5)

```markdown
# ペイロード

## 対象ユニット
{IaC生成の対象ユニット一覧}

## コード生成方針
- 言語/フレームワーク: {論理設計で決定}
- クラウドプロバイダー: {AWS / GCP / Azure}
- IaCツール: {CDK / CloudFormation / Terraform}

## サービスマッピングサマリー
| ドメインコンポーネント | クラウドサービス | 根拠ADR |
|---------------------|----------------|---------|
| {コンポーネント名} | {サービス名} | ADR-{N} |

## 全ボルトのテスト結果
| ボルト | ユニットテスト | 統合テスト | 受け入れテスト | 結果 |
|--------|-------------|----------|-------------|------|
| Bolt-{N} | {N}件パス | {N}件パス | {N}件パス | 全件パス |

## 横断レビュー結果サマリー
{不整合ゼロ / 残課題があれば概要}
```

### 4.4 to_release.md (S5 → S6)

```markdown
# ペイロード

## デプロイメントユニット一覧
| ユニット | パッケージ種別 | IaCパス | テスト結果 |
|----------|-------------|---------|----------|
| {ユニット名} | {Lambda / Container / etc} | {パス} | 全件パス |

## 環境要件
- クラウドプロバイダー: {AWS / GCP / Azure}
- 必要なアカウント/プロジェクト: {情報}
- ネットワーク前提: {VPC構成など}

## NFRからのSLA基準
| 指標 | 基準値 | 測定方法 |
|------|--------|---------|
| {レスポンスタイム} | {Xms} | {方法} |
| {可用性} | {X%} | {方法} |

## リスク緩和策
{risk_description.md から運用リスクに関する項目を抜粋}
```

### 4.5 to_operate.md (S6 → S7)

```markdown
# ペイロード

## デプロイ済み環境情報
| 環境 | エンドポイント | デプロイ日 | バージョン |
|------|-------------|----------|----------|
| {staging/prod} | {URL} | {日付} | {バージョン} |

## モニタリング構成
- ダッシュボード: {パス/URL}
- アラーム定義: {パス}
- ランブック: {パス}

## ビジネスKPI（運用開始後の追跡対象）
| KPI | 目標値 | 測定方法 | 関連ストーリー |
|-----|--------|---------|--------------|
| {KPI名} | {目標} | {手段} | {US-XXX} |

## CI/CDパイプライン情報
{パイプライン定義のパス、トリガー条件、承認ゲートの有無}
```

---

## 5. スキルが実装すべきインターフェース

各スキルは以下の3つのインターフェースを満たす。

### 5.1 起動時 (on_start)

```
1. manifest.md を読み込む（なければ作成）
2. 対応するハンドオフファイルを読み込む
3. ハンドオフの prerequisites を検証する
   - 充足 → 正常起動、ペイロードを読み込み作業開始
   - 未充足 → ユーザーに報告し、先行スキルの実行を推奨
4. prompts.md にセッション開始を記録
```

### 5.2 成果物生成時 (on_artifact)

```
1. 成果物ファイルを所定パスに保存
2. manifest.md に行を追記（ID, パス, 生成元, ステータス, 日付）
3. ステータスが変わった場合は既存行を更新
```

### 5.3 完了時 (on_complete)

```
1. 次スキルへのハンドオフファイルを生成（共通ヘッダー + ペイロード）
2. manifest.md の自スキル成果物のステータスを最終確認
3. prompts.md にセッション完了を記録
4. ユーザーに完了報告と次のステップを提示
```

---

## 6. build-bolt スキル内部のハンドオフ

build-bolt はスキル内部で設計→テスト→実装を一貫して行う。
スキル間ハンドオフは不要だが、**ステップ間のコンテキスト受け渡し** が発生する。

これはサブエージェント呼び出し時の入力仕様で対応する（別文書で定義予定）。

```
build-bolt 内部のコンテキストフロー:

step1 (ドメイン設計)
  → 出力: domain_model.md → manifest に登録
  → step2 の入力として参照

step2 (論理設計)
  → 出力: logical_design.md, ADR → manifest に登録
  → step3 の入力として参照

step3 (テスト契約)
  → A4:test-generator に渡す入力:
    - domain_model.md
    - 受け入れ基準（ストーリーファイル）
  → 出力: テストコード → manifest に登録
  → 人間が承認

step4 (ドメイン実装)
  → A5:code-generator に渡す入力:
    - 承認済みテストコード
    - domain_model.md
  → A6:refactorer に渡す入力:
    - テスト＋実装コード
  → 出力: 実装コード → manifest に登録

step5 (インフラ実装)
  → A7:infra-impl に渡す入力:
    - logical_design.md
    - integration_specs.md
  → 出力: インフラコード＋統合テスト → manifest に登録

step6 (検証)
  → A8:verification-report + A1:cross-review
  → 出力: 検証レポート → manifest に登録
```

---

## 7. 現行からの移行

| 現行ファイル | 改訂後 | 変更 |
|------------|--------|------|
| story-artifacts/handoff_to_units.md | handoffs/to_units.md | 共通ヘッダー追加、パスをmanifest参照に |
| design-artifacts/handoff_to_build.md | handoffs/to_build.md | 共通ヘッダー追加、パスをmanifest参照に |
| design-artifacts/handoff_to_implementation.md | **廃止** | build-bolt統合により不要 |
| （なし） | manifest.md | 新規 |
| （なし） | handoffs/to_iac.md | 新規 |
| （なし） | handoffs/to_release.md | 新規 |
| （なし） | handoffs/to_operate.md | 新規 |
