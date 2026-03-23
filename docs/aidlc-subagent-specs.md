# AI-DLC サブエージェント入出力仕様

## ステータス: v0.2.0 確定

---

## 1. サブエージェント共通仕様

### 1.1 呼び出しパターン

サブエージェントはスキル内のステップから呼び出される。
呼び出しは以下の3要素で構成される:

```
[呼び出し]
  directive: {サブエージェントへの指示（自然言語）}
  inputs:    {入力ファイルパスのリスト}
  outputs:   {期待される出力先パスのリスト}
```

- **directive** — サブエージェントが何をすべきかを記述する。パラメータ化可能な部分を `{変数名}` で示す。
- **inputs** — サブエージェントに渡すファイル。これが隔離コンテキストの全体。会話履歴は渡さない。
- **outputs** — サブエージェントが生成するファイルの保存先。スキルが事前にパスを指定する。

### 1.2 実行結果

サブエージェントは実行後、以下を返す:

```
[結果]
  status:    {success / failure / needs_human}
  outputs:   {実際に生成されたファイルパスのリスト}
  summary:   {実行結果の要約（1〜3文）}
  issues:    {検出された問題のリスト（あれば）}
```

- **needs_human** — サブエージェント内で判断できない問題が見つかった場合。スキルが人間に提示する。

### 1.3 エラーハンドリング

サブエージェントが失敗した場合のスキル側の対応:

1. `failure` → スキルがエラー内容をユーザーに提示し、入力の修正または再実行を判断
2. `needs_human` → スキルが issues の内容をユーザーに提示し、判断を仰ぐ
3. タイムアウト → スキルが部分的な出力を確認し、続行可否をユーザーに判断してもらう

---

## 2. build-bolt 内サブエージェント詳細仕様

### 2.1 A4: test-generator

**目的:** ドメインモデルと受け入れ基準からテストコードを生成する。

**呼び出し元:** build-bolt step3（テスト契約）

**directive:**
```
以下のドメインモデルと受け入れ基準から、{flavor}フレーバーに基づくテストコードを生成せよ。
テストは以下の基準を満たすこと:
- 各テストは1つの振る舞いだけを検証する（Single Assertion Principle）
- テスト名がそのまま仕様書として読める命名にする
- 正常系・異常系・境界値を網羅する
- テストはドメインモデルの用語で書く（技術用語ではなくビジネス用語）
テスト対象のクラス/関数のスタブ（空の実装）も生成せよ。
テストが構文的に有効な状態にすること。
```

**inputs:**
| # | ファイル | 用途 |
|---|---------|------|
| 1 | `design-artifacts/domain-models/{unit}_domain_model.md` | コンポーネント・属性・振る舞い・ビジネスルールの抽出元 |
| 2 | `story-artifacts/{領域}_stories.md` | 受け入れ基準の抽出元（1:1でテストケースに変換） |
| 3 | `design-artifacts/logical-designs/{unit}_logical_design.md` | 技術スタック情報（言語、フレームワーク、テストライブラリ） |

**パラメータ:**
| パラメータ | 値 | 説明 |
|-----------|-----|------|
| flavor | DDD / BDD / TDD | テスト導出方法を決定 |
| language | Python / TypeScript / etc | コード生成の言語 |
| test_framework | pytest / jest / etc | テストフレームワーク |

**outputs:**
| # | ファイル | 内容 |
|---|---------|------|
| 1 | `{project}/tests/unit/` | ユニットテスト（ドメインモデルの振る舞いごと） |
| 2 | `{project}/tests/acceptance/` | 受け入れテスト（受け入れ基準ごと） |
| 3 | `{project}/src/domain/` | スタブファイル（空のクラス/関数定義） |

**フレーバー別の導出ルール:**
- **DDD:** 各集約ルートの不変条件・ドメインイベント発行条件をテスト化。エンティティの等値性、値オブジェクトの不変性もテスト対象。
- **BDD:** 受け入れ基準のGiven-When-Then形式をそのままテストシナリオに変換。
- **TDD:** テスト観点マトリクス（ストーリーごとの入力/出力/境界値/例外）からテストを導出。

**成功基準:**
- 全テストファイルが構文的に有効（import解決、型チェック通過）
- テスト実行可能（全件 fail するが、構文エラーではなく AssertionError 等）
- 受け入れ基準とテストの1:1対応が明示されている（テスト名にUS-IDを含む）

**ツール制限:**
- tools: Read, Write, Glob, Grep, Bash
- disallowedTools: Edit, WebFetch, WebSearch

---

### 2.2 A5: code-generator

**目的:** 承認済みテストを通すドメインレイヤーの実装コードを生成する。

**呼び出し元:** build-bolt step4（ドメイン実装 — Green フェーズ）

**directive:**
```
以下の承認済みテストを全件パスさせる実装コードを生成せよ。
ドメインモデルの設計仕様に準拠すること。
テストがすべて通ることを最優先とする。
論理設計で決定されたパターン（{patterns}）を適用すること。
```

**inputs:**
| # | ファイル | 用途 |
|---|---------|------|
| 1 | `{project}/tests/` | 承認済みテストコード（これが「契約」） |
| 2 | `{project}/src/domain/` | A4が生成したスタブ（置き換え対象） |
| 3 | `design-artifacts/domain-models/{unit}_domain_model.md` | 属性・振る舞い・ビジネスルールの実装ガイド |
| 4 | `design-artifacts/logical-designs/{unit}_logical_design.md` | パターン適用の参照（CQRS、イベント駆動等） |

**パラメータ:**
| パラメータ | 値 | 説明 |
|-----------|-----|------|
| patterns | CQRS / EventDriven / etc | 論理設計で決定したパターン |
| language | Python / TypeScript / etc | 実装言語 |

**outputs:**
| # | ファイル | 内容 |
|---|---------|------|
| 1 | `{project}/src/domain/` | 実装コード（スタブを置き換え） |
| 2 | `{project}/src/application/` | アプリケーションサービス（必要な場合） |

**成功基準:**
- テスト全件パス
- ドメインモデルに定義されたコンポーネント名・メソッド名と実装が一致
- ドメインモデルにないクラスやメソッドが追加されていない

**失敗時の振る舞い:**
- テストが通らない場合: `status: failure` + 失敗したテストと原因分析を `issues` に含める
- build-boltスキルが再実行を判断（入力修正なしでリトライ可能）

**ツール制限:**
- tools: Read, Write, Edit, Glob, Grep, Bash
- disallowedTools: WebFetch, WebSearch

---

### 2.3 A6: refactorer

**目的:** Green状態のコードの品質を改善する。テストが通り続ける限り安全。

**呼び出し元:** build-bolt step4（ドメイン実装 — Refactor フェーズ）

**directive:**
```
以下のコードの品質を改善せよ。改善対象:
- 重複コードの排除
- デザインパターンの適用（ADRで承認済みのパターンを参照）
- 可読性の向上（命名、構造の整理）
- パフォーマンスの最適化
テストが全件パスし続けることを保証すること。
テストを変更してはならない。
```

**inputs:**
| # | ファイル | 用途 |
|---|---------|------|
| 1 | `{project}/src/domain/` | リファクタリング対象コード |
| 2 | `{project}/src/application/` | リファクタリング対象コード |
| 3 | `{project}/tests/` | テスト（変更不可、リグレッション検出に使用） |
| 4 | `design-artifacts/adrs/` | 承認済みパターンの参照 |

**パラメータ:** なし（ADRから自動判断）

**outputs:**
| # | ファイル | 内容 |
|---|---------|------|
| 1 | `{project}/src/domain/` | 改善済みコード |
| 2 | `{project}/src/application/` | 改善済みコード |
| 3 | （テスト実行結果） | 全件パスの確認 |

**成功基準:**
- テスト全件パス（リグレッションゼロ）
- テストコードが変更されていない

**特記事項:**
- このサブエージェントは「改善提案を返す」のではなく「改善済みコードを返す」。
  提案の選択が必要だった旧設計から変更し、テストが通る限り自動適用する。
- テストが落ちる改善は自動ロールバックし、`issues` にその旨を報告。

**ツール制限:**
- tools: Read, Edit, Glob, Grep, Bash
- disallowedTools: Write, WebFetch, WebSearch

---

### 2.4 A7: infra-impl

**目的:** 論理設計に基づくインフラレイヤーの実装と統合テストを生成する。

**呼び出し元:** build-bolt step5（インフラ実装）

**directive:**
```
以下の論理設計仕様に基づき、インフラストラクチャレイヤーの実装コードと統合テストを生成せよ。
統合テストはドメイン実装との結合点を検証すること。
サービスマッピングに従い、適切なクラウドサービスのSDK/クライアントを使用すること。
```

**inputs:**
| # | ファイル | 用途 |
|---|---------|------|
| 1 | `design-artifacts/logical-designs/{unit}_logical_design.md` | サービスマッピング、通信設計、データ設計 |
| 2 | `design-artifacts/integration_specs.md` | ユニット間の統合仕様（API契約、イベント契約） |
| 3 | `{project}/src/domain/` | ドメインレイヤーの公開インターフェース（依存先として参照） |
| 4 | `design-artifacts/adrs/` | インフラ選定に関するADR |

**パラメータ:**
| パラメータ | 値 | 説明 |
|-----------|-----|------|
| cloud_provider | AWS / GCP / Azure | クラウドプロバイダー |
| services | DynamoDB, Lambda, etc | 使用サービスリスト |

**outputs:**
| # | ファイル | 内容 |
|---|---------|------|
| 1 | `{project}/src/infrastructure/` | インフラ実装コード |
| 2 | `{project}/tests/integration/` | 統合テスト |
| 3 | `{project}/src/infrastructure/config/` | 環境変数・構成ファイル |

**成功基準:**
- 統合テストが構文的に有効
- ドメインレイヤーの公開インターフェースのみに依存（内部実装への依存なし）
- サービスマッピングと実際の使用サービスが一致

**特記事項:**
- 統合テストの生成は行うが、テストの承認は build-bolt スキルが人間に委ねる。
- したがってこのサブエージェントは `status: needs_human` で返すのが正常フロー。
  `summary` に「統合テストの人間レビューが必要です」を含める。

**ツール制限:**
- tools: Read, Write, Edit, Glob, Grep, Bash
- disallowedTools: WebFetch, WebSearch

---

### 2.5 A8: verification-report

**目的:** 全テストの一括実行と検証レポートの生成。

**呼び出し元:** build-bolt step6（横断検証）

**directive:**
```
以下のプロジェクトの全テスト（ユニット + 統合 + 受け入れ）を一括実行し、
結果を検証レポートとしてまとめよ。
カバレッジ情報も取得すること。
Red-Green-Refactorの各フェーズの実行記録も含めること。
```

**inputs:**
| # | ファイル | 用途 |
|---|---------|------|
| 1 | `{project}/` | プロジェクト全体（テスト実行対象） |

**パラメータ:**
| パラメータ | 値 | 説明 |
|-----------|-----|------|
| bolt_name | Bolt-{N} | レポートのラベル用 |

**outputs:**
| # | ファイル | 内容 |
|---|---------|------|
| 1 | `reports/verification_report_{bolt}.md` | 検証レポート |

**レポートフォーマット:**
```markdown
# 検証レポート: {bolt_name}

## テスト結果サマリー
| テスト種別 | 件数 | 成功 | 失敗 | スキップ |
|-----------|------|------|------|---------|
| ユニットテスト | {N} | {N} | {N} | {N} |
| 統合テスト | {N} | {N} | {N} | {N} |
| 受け入れテスト | {N} | {N} | {N} | {N} |

## カバレッジ
- ドメインレイヤー: {X}%
- インフラレイヤー: {X}%
- アプリケーションレイヤー: {X}%

## 失敗テスト詳細（あれば）
| テスト | エラー | 推定原因 |

## Red-Green-Refactorサイクル記録
| フェーズ | テスト結果 | 備考 |
```

**成功基準:**
- レポートが生成されること（テスト結果が全件パスでなくてもレポートは生成する）

**ツール制限:**
- tools: Read, Write, Glob, Grep, Bash
- disallowedTools: Edit, WebFetch, WebSearch

---

### 2.6 A1: cross-review（汎用・再利用可能）

**目的:** 複数の成果物間の横断的な整合性をチェックする。

**呼び出し元:** 全スキル・全フェーズから呼び出し可能

**directive:**
```
以下の成果物群を読み込み、指定されたレビュー観点に基づいて横断的な不整合を検出せよ。
不整合が見つかった場合:
- 自動修正可能なもの → 修正案を生成
- 判断が必要なもの → issues として報告
```

**inputs:** 呼び出し元が動的に指定（固定ではない）

**パラメータ:**
| パラメータ | 値 | 説明 |
|-----------|-----|------|
| review_perspective | リスト（下記参照） | レビュー観点のID一覧 |
| target_files | ファイルパスのリスト | レビュー対象 |
| fix_mode | auto_fix / report_only | 自動修正するか報告のみか |

**レビュー観点カタログ:**

| 観点ID | 観点 | 使用フェーズ |
|--------|------|------------|
| TERM_CONSISTENCY | 用語の一貫性（ストーリー間、モデルと用語集） | 構想、構築 |
| NFR_COVERAGE | NFR参照の整合性（全NFRがカバーされているか） | 構想、構築 |
| RISK_COVERAGE | リスク参照の整合性 | 構想 |
| KPI_TRACEABILITY | KPIの追跡可能性（KPI→ストーリー→テスト） | 構想 |
| AC_COMPLETENESS | 受け入れ基準の網羅性 | 構想 |
| STORY_DESIGN_ALIGN | ストーリーとドメインモデルの整合 | 構築 |
| NFR_PATTERN_ALIGN | NFRとパターン適用の整合 | 構築 |
| ADR_IMPL_ALIGN | ADR決定と実装の整合 | 構築 |
| CODE_MODEL_ALIGN | コードとドメインモデルの整合 | 構築 |
| AC_TEST_ALIGN | 受け入れ基準とテストの1:1対応 | 構築 |
| SERVICE_IAC_ALIGN | サービスマッピングとIaCの整合 | 構築(IaC) |

**outputs:**
| # | ファイル | 内容 |
|---|---------|------|
| 1 | `reports/cross_review_report.md` | レビュー結果 |
| 2 | （修正済みファイル群） | fix_mode=auto_fixの場合のみ |

**レビュー結果フォーマット:**
```markdown
# 横断レビューレポート

## レビュー対象
{ファイル一覧}

## 適用した観点
{観点ID一覧}

## 検出結果
| # | 観点ID | 内容 | 深刻度 | 対応 | ステータス |
|---|--------|------|--------|------|----------|
| 1 | {ID} | {不整合の内容} | {高/中/低} | {自動修正 / 要判断} | {修正済み/確認待ち} |

## 修正済みファイル
{修正が入ったファイル一覧と変更内容の要約}
```

**ツール制限:**
- tools: Read, Write, Edit, Glob, Grep
- disallowedTools: Bash, WebFetch, WebSearch

---

## 3. build-bolt からの呼び出しシーケンス

各ステップからのサブエージェント呼び出しを時系列で示す。

```
build-bolt step2 完了後:
  → A1:cross-review を呼び出し
    review_perspective: [STORY_DESIGN_ALIGN, NFR_PATTERN_ALIGN, TERM_CONSISTENCY]
    target_files: [domain_model, logical_design, stories, nfr, adrs, ubiquitous_language]
    fix_mode: auto_fix
  → 結果を人間に提示

build-bolt step3:
  → A4:test-generator を呼び出し
    inputs: [domain_model, stories, logical_design]
    flavor: {manifest.mdから取得}
  → 生成されたテストを人間に提示 → 承認待ち
  → 承認後、テスト実行して全件fail確認 (Red)

build-bolt step4:
  → A5:code-generator を呼び出し
    inputs: [tests, stubs, domain_model, logical_design]
  → テスト実行して全件pass確認 (Green)
  → A6:refactorer を呼び出し
    inputs: [src, tests, adrs]
  → テスト実行してリグレッションなし確認

build-bolt step5:
  → A7:infra-impl を呼び出し
    inputs: [logical_design, integration_specs, domain_src, adrs]
  → 統合テストを人間に提示 → 承認待ち
  → 承認後、Red → Green サイクル実行

build-bolt step6:
  → A8:verification-report を呼び出し
    inputs: [project_root]
  → A1:cross-review を呼び出し
    review_perspective: [CODE_MODEL_ALIGN, AC_TEST_ALIGN, ADR_IMPL_ALIGN]
    target_files: [src, tests, domain_model, logical_design, adrs, stories]
    fix_mode: report_only
  → 両結果を統合して人間に提示
```


### 3.1 A2: handoff-generator（汎用・再利用可能）

**目的:** スキル完了時にハンドオフ文書を自動生成する。

**呼び出し元:** 全スキルの on_complete 処理

**directive:**
```
manifest.md と現在のスキルの成果物から、次スキルへのハンドオフ文書を生成せよ。
共通ヘッダー（type, from, to, created, status, manifest, prerequisites）と
スキル固有ペイロードを含むこと。
aidlc-interface-contract.md のフォーマットに準拠すること。
```

**inputs:**
| # | ファイル | 用途 |
|---|---------|------|
| 1 | `aidlc-docs/manifest.md` | 成果物台帳（ステータス確認） |
| 2 | スキル固有の成果物ファイル群 | ペイロード生成の情報源 |
| 3 | `docs/aidlc-interface-contract.md` | ハンドオフフォーマット参照 |

**パラメータ:**
| パラメータ | 値 | 説明 |
|-----------|-----|------|
| from_skill | S1〜S7 | 生成元スキルID |
| to_skill | S2〜S7 | 宛先スキルID |

**outputs:**
| # | ファイル | 内容 |
|---|---------|------|
| 1 | `aidlc-docs/handoffs/to_{target}.md` | ハンドオフ文書 |

**成功基準:**
- 共通ヘッダーの全必須フィールドが設定されている
- prerequisites が manifest.md の現在のステータスと整合している

**ツール制限:**
- tools: Read, Write, Glob, Grep
- disallowedTools: Edit, Bash, WebFetch, WebSearch

---

## 4. 構想フェーズのサブエージェント仕様

### 4.1 A3: story-quality-check

**目的:** ストーリーがINVEST基準を満たすか検証する。

**呼び出し元:** S1:user-stories step3（ストーリー詳細化の各ステップ後）

**inputs:**
| # | ファイル | 用途 |
|---|---------|------|
| 1 | `story-artifacts/{領域}_stories.md` | 検証対象ストーリー |

**outputs:**
| # | ファイル | 内容 |
|---|---------|------|
| 1 | （なし — 結果をsummary/issuesで返す） | 各ストーリーのINVEST評価 |

**issues フォーマット:**
```
- US-001: ストーリーが大きすぎる（S基準違反）→ 分割を推奨
- US-003: 受け入れ基準が曖昧（T基準違反）→ 具体的な検証条件に修正を推奨
```

**ツール制限:**
- tools: Read, Glob, Grep
- disallowedTools: Write, Edit, Bash, WebFetch, WebSearch

---

## 5. IaC・リリース・運用フェーズのサブエージェント仕様

### 5.1 A9: iac-generator

**呼び出し元:** S5:iac

**inputs:**
| # | ファイル | 用途 |
|---|---------|------|
| 1 | `design-artifacts/logical-designs/{unit}_logical_design.md` | サービスマッピング |
| 2 | `design-artifacts/adrs/` | インフラ関連ADR |
| 3 | `requirements/nfr_definition.md` | スケーラビリティ・可用性要件 |
| 4 | `{project}/src/infrastructure/` | インフラ実装コード（デプロイ対象の確認） |

**パラメータ:**
| パラメータ | 値 | 説明 |
|-----------|-----|------|
| iac_tool | CDK / CloudFormation / Terraform | IaCツール |
| cloud_provider | AWS / GCP / Azure | クラウドプロバイダー |

**outputs:**
| # | ファイル | 内容 |
|---|---------|------|
| 1 | `{project}/iac/` | IaCコード |
| 2 | `{project}/iac/README.md` | デプロイ手順書 |

**ツール制限:**
- tools: Read, Write, Glob, Grep, Bash
- disallowedTools: Edit, WebFetch, WebSearch

### 5.2 A10: pipeline-generator

**呼び出し元:** S6:release

**inputs:**
| # | ファイル | 用途 |
|---|---------|------|
| 1 | `{project}/iac/` | デプロイ対象 |
| 2 | `{project}/tests/` | CI実行対象テスト |
| 3 | `requirements/nfr_definition.md` | SLA基準（承認ゲート条件） |

**outputs:**
| # | ファイル | 内容 |
|---|---------|------|
| 1 | `{project}/ci/` | パイプライン定義ファイル |

**ツール制限:**
- tools: Read, Write, Glob, Grep
- disallowedTools: Edit, Bash, WebFetch, WebSearch

### 5.3 A11: monitoring-setup

**呼び出し元:** S6:release

**inputs:**
| # | ファイル | 用途 |
|---|---------|------|
| 1 | `design-artifacts/logical-designs/{unit}_logical_design.md` | モニタリング対象サービス |
| 2 | `requirements/nfr_definition.md` | SLA基準（アラーム閾値） |
| 3 | `requirements/business_metrics.md` | ビジネスKPI（ダッシュボード項目） |
| 4 | `requirements/risk_description.md` | 運用リスク（ランブック項目） |

**outputs:**
| # | ファイル | 内容 |
|---|---------|------|
| 1 | `{project}/monitoring/dashboards/` | ダッシュボード定義 |
| 2 | `{project}/monitoring/alarms/` | アラーム定義 |
| 3 | `{project}/monitoring/runbooks/` | ランブック |

**ツール制限:**
- tools: Read, Write, Glob, Grep
- disallowedTools: Edit, Bash, WebFetch, WebSearch
