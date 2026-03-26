# テスト先行戦略ガイド

## 核心思想：テスト＝人間とAIの契約

AI-DLCでは、全フレーバー（DDD/BDD/ストーリーベース）共通で**テストを先に書く**。

テストはシステムの「正しさの定義」であり、人間がレビュー・承認することで
「契約」として確定する。AIはその契約を満たすコードを生成する責任を持つ。
テストが通れば、人間が定義した正しさが実装に反映されたことが保証される。

この構造が機能するために、テストの品質が極めて重要になる。
テストに漏れがあれば契約が不完全になり、テストが誤っていれば
間違った正しさが実装される。だからこそ人間のレビューが不可欠。

---

## テストピラミッド

```
        /  受け入れテスト  \     ← 少数、ストーリーの受け入れ基準に1:1対応
       /  統合テスト        \    ← 中程度、コンポーネント間連携
      /  ユニットテスト      \   ← 大量、ドメインロジック中心、高速
```

| テスト層 | 対象 | 速度 | 外部依存 | 件数目安 |
|---------|------|------|---------|---------|
| ユニットテスト | ドメインロジック、ビジネスルール | ミリ秒 | すべてモック | 1メソッドにつき2〜5件 |
| 統合テスト | リポジトリ実装、API、外部連携 | 秒 | ローカルモック環境 | 1ユースケースにつき2〜3件 |
| 受け入れテスト | エンドツーエンドの振る舞い | 秒〜分 | ローカルモック環境 | 1ストーリーにつき1〜3件 |

Red-Green-Refactorサイクルでは、ユニットテストと受け入れテストを
ステップ2（Red）で先に生成する。統合テストはステップ7（インフラ実装）で生成する。

---

## テスト導出方法：ソースから何を引き出すか

### 受け入れ基準 → 受け入れテスト

ストーリーの受け入れ基準を1:1でテストケースに変換する。
これが最上位の契約であり、ビジネス要件の充足を保証する。

**DDD/ストーリーベースフレーバーの受け入れ基準：**
```markdown
受け入れ基準:
1. 購入履歴のない買い物客には、全体の人気商品ランキングに基づくレコメンデーションが表示される
2. 閲覧履歴がある場合は、閲覧カテゴリの人気商品が優先される
3. 人気商品ランキングは日次で更新される
```

→ テストに変換：
```python
class TestUS004_DefaultRecommendation:
    """US-004: 新規買い物客へのデフォルトレコメンデーション"""

    def test_new_customer_gets_popular_items(self):
        """受け入れ基準1: 購入履歴なし → 人気商品ランキングに基づくレコメンデーション"""
        # テスト対象のクラスはまだ存在しない（スタブのみ）
        engine = RecommendationEngine(fallback, ranking)
        result = engine.recommend(customer_id="NEW-001", context="page")
        assert result.algorithm == "default_popular"
        assert len(result.items) >= 3

    def test_browsed_categories_are_prioritized(self):
        """受け入れ基準2: 閲覧履歴あり → 閲覧カテゴリの人気商品を優先"""
        engine = RecommendationEngine(fallback, ranking)
        result = engine.recommend(
            customer_id="BROWSE-001",
            context="page",
            browsed_category_ids=["CAT-1"],
        )
        reasons = {item.reason for item in result.items}
        assert RecommendationReason.CATEGORY_POPULAR in reasons
```

**BDDフレーバーのGiven-When-Then：**
```markdown
シナリオ1: 単一商品の在庫が閾値を下回る
- Given: 商品Aの在庫閾値が100個に設定されている
- And: 現在の在庫数が105個である
- When: 出庫により在庫数が95個に減少する
- Then: 在庫閾値割れイベントが生成される
```

→ テストに変換（構造がほぼそのまま）：
```python
def test_scenario_1_single_product_below_threshold(self):
    """シナリオ1: 単一商品の在庫が閾値を下回る"""
    # Given
    product = Product(id="A", threshold=100)
    inventory = Inventory(product=product, quantity=105)
    # When
    event = inventory.process_shipment(quantity=10)
    # Then
    assert event is not None
    assert event.current_stock == 95
```

### ドメインモデル → ユニットテスト

ドメインモデルの各コンポーネントから以下を引き出してテストにする：

| モデルの要素 | テスト対象 | 例 |
|-------------|----------|-----|
| 値オブジェクトの不変条件 | コンストラクタのバリデーション | スコアが0〜1の範囲外ならエラー |
| 集約のビジネスルール | 振る舞いメソッドの入出力 | 最低3件、最大10件の制約 |
| ドメインサービスのロジック | アルゴリズムの振る舞い | フォールバック判定の正しさ |
| ドメインイベント | イベント発行の条件とペイロード | 生成完了時にイベントが発火する |
| エンティティの状態遷移 | 状態変更メソッドの前後条件 | 購入除外後のリスト内容 |

---

## スタブの書き方

テスト先行では、テスト対象のクラスがまだ存在しない。
最小限のスタブを作成してテストを構文的に有効にする。

```python
# recommendation_engine/domain/models/recommendation.py（スタブ）

class Recommendation:
    """レコメンデーション集約ルート — 実装はGreenフェーズで追加"""

    def __init__(self, recommendation_id, customer_id, context):
        raise NotImplementedError("Greenフェーズで実装")

    @property
    def items(self):
        raise NotImplementedError

    @property
    def algorithm(self):
        raise NotImplementedError

    def set_items(self, items, algorithm):
        raise NotImplementedError

    def exclude_purchased(self, purchased_product_ids):
        raise NotImplementedError

    def fallback_to_default(self, ranking):
        raise NotImplementedError

    def finalize(self):
        raise NotImplementedError

    @property
    def is_sufficient(self):
        raise NotImplementedError
```

スタブのポイント：
- 公開インターフェース（メソッドシグネチャ）だけを定義する
- 全メソッドは `NotImplementedError` を送出する
- テスト実行時に「Red」（全件失敗）を確認できる状態にする
- スタブはドメインモデルの「振る舞い」表から機械的に導出できる

---

## テスト命名規則

テスト名はそのまま仕様書として読めることが重要。
人間がレビューする際に、テスト名だけで「何を検証しているか」が伝わる必要がある。

**良い命名：**
- `test_new_customer_gets_popular_items` — ビジネス用語で振る舞いを記述
- `test_score_below_zero_raises_error` — 不変条件違反を明示
- `test_purchased_items_excluded_from_results` — ビジネスルールを直接表現

**悪い命名：**
- `test_recommend_1` — 何をテストしているか不明
- `test_negative_case` — 具体性がない
- `test_method_returns_list` — 技術的で、ビジネス上の意味がない

---

## テストレビューのチェックリスト

人間がテストをレビューする際の観点：

1. **網羅性** — 受け入れ基準のすべてがテストケースに対応しているか
2. **期待値の正しさ** — assertの値がビジネスロジックとして正しいか
3. **境界値** — エッジケース（0件、最大件数、空入力等）がカバーされているか
4. **異常系** — バリデーションエラー、障害時のフォールバックがテストされているか
5. **独立性** — テスト間に順序依存がないか
6. **可読性** — テスト名と構造から仕様が読み取れるか

---

## テストデータの管理

```python
# tests/fixtures/profiles.py

def create_customer_with_history(product_count=10):
    """十分な購入履歴を持つ買い物客"""
    return CustomerProfile(
        customer_id="C-TEST-001",
        behavior_signals=[
            BehaviorSignal(product_id=f"P-{i}", signal_type="purchase")
            for i in range(product_count)
        ],
        purchased_product_ids={f"P-{i}" for i in range(product_count)},
    )

def create_new_customer():
    """購入履歴のない新規買い物客"""
    return CustomerProfile(
        customer_id="C-TEST-NEW",
        behavior_signals=[],
        purchased_product_ids=set(),
    )
```

---

## ローカルモック環境

統合テストはLocalStack（AWS）またはTestcontainersを使用し、
実環境に依存しないローカル実行を保証する。

```python
@pytest.fixture
def dynamodb_table():
    """LocalStackのDynamoDBテーブル"""
    client = boto3.client("dynamodb", endpoint_url="http://localhost:4566")
    client.create_table(...)
    yield table_name
    client.delete_table(TableName=table_name)
```

---

## カバレッジ目標

| レイヤー | カバレッジ目標 | 根拠 |
|---------|-------------|------|
| ドメインレイヤー | 90%以上 | ビジネスロジックの信頼性が最重要 |
| アプリケーションレイヤー | 80%以上 | ユースケースのオーケストレーション |
| インフラレイヤー | 60%以上 | 統合テストで補完 |
