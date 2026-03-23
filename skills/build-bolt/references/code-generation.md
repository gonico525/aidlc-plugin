# コード生成パターンとディレクトリ構造

## ディレクトリ構造の原則

AI-DLCではクリーンアーキテクチャ（ヘキサゴナルアーキテクチャ）の層構造を基本とし、
ドメインロジックを外部依存から完全に分離する。

### Python プロジェクト構造（推奨）

```
{unit_name}/
├── domain/                    # ドメインレイヤー（ビジネスロジック、外部依存なし）
│   ├── models/                # エンティティ、値オブジェクト、集約
│   │   ├── __init__.py
│   │   ├── {aggregate}.py
│   │   └── {value_object}.py
│   ├── services/              # ドメインサービス
│   │   └── {service}.py
│   ├── events/                # ドメインイベント
│   │   └── {event}.py
│   └── repositories/          # リポジトリインターフェース
│       └── {repository}.py
├── application/               # アプリケーションレイヤー（ユースケースのオーケストレーション）
│   ├── handlers/              # ユースケースハンドラー
│   │   └── {handler}.py
│   └── dto/                   # データ転送オブジェクト
│       └── {dto}.py
├── infrastructure/            # インフラレイヤー（外部依存の実装）
│   ├── persistence/           # リポジトリの具体実装
│   │   └── dynamodb_{repository}.py
│   ├── external/              # 外部サービス連携
│   │   └── {adapter}.py
│   ├── api/                   # APIハンドラー（Lambda等）
│   │   └── {endpoint}.py
│   └── config/                # 環境設定
│       └── settings.py
├── iac/                       # IaCコード
│   ├── stacks/
│   │   └── {stack}.py
│   └── app.py
├── tests/
│   ├── unit/                  # ユニットテスト（ドメインレイヤー中心）
│   │   ├── domain/
│   │   └── application/
│   ├── integration/           # 統合テスト
│   │   └── infrastructure/
│   └── acceptance/            # 受け入れテスト
│       └── features/
├── requirements.txt
└── README.md
```

### TypeScript/Node.js プロジェクト構造

```
{unit_name}/
├── src/
│   ├── domain/
│   ├── application/
│   ├── infrastructure/
│   └── index.ts
├── iac/
├── test/
│   ├── unit/
│   ├── integration/
│   └── acceptance/
├── package.json
└── tsconfig.json
```

---

## Red-Green-Refactorにおけるコード生成の流れ

### Redフェーズ：スタブの生成

テスト生成と同時に、テスト対象クラスの**スタブ**（公開インターフェースのみ）を生成する。
スタブはドメインモデルの「コンポーネント詳細」から機械的に導出できる。

スタブの原則：
- ドメインモデルに記載された属性と振る舞いのシグネチャだけを定義する
- 全メソッドは `NotImplementedError` を送出する
- テストがインポート・実行できる（構文的に有効な）最小限の形にする
- ビジネスロジックは一切含めない

### Greenフェーズ：スタブを実装に置き換え

人間がテストを承認した後、スタブを実際の実装に置き換える。

Greenフェーズのコード生成原則：
- **テストが通ることが最優先目標** — テストが定義した契約を満たすコードを書く
- **ドメインモデルの設計に従う** — 属性・振る舞い・ビジネスルールをモデルから忠実に変換
- **完全な実装を生成してよい** — 人間にとってのTDDでは「最小限」が重要だが、AIが生成する場合は承認済みテストが通る完全な実装を一度に出すほうが効率的。テストが契約として機能しているので、実装の完全性は問題にならない
- **テストに書かれていない振る舞いを追加しない** — テストが定義していない暗黙の機能を実装しない

### Refactorフェーズ：品質改善

テストが全件パスした後のリファクタリング。テストがセーフティネットとして機能する。

リファクタリングの対象：
- 重複コードの共通化
- 命名の改善
- メソッドの分割・統合
- デザインパターンの適用

リファクタリング後に必ずテストを再実行し、リグレッションがないことを確認する。

---

## フレーバー別のコード生成パターン

### DDDフレーバー

ドメインモデルの戦術パターンを忠実にコードに反映する。

**集約ルートの実装パターン：**
```python
class Recommendation:
    """レコメンデーション集約ルート"""
    
    def __init__(self, recommendation_id, customer_id, context):
        self._id = recommendation_id
        self._customer_id = customer_id
        self._context = context
        self._items = []
        self._algorithm = None
        self._generated_at = None
        self._events = []  # ドメインイベントの蓄積
    
    def generate(self, profile, context):
        """レコメンデーションを生成する"""
        # ビジネスルールの適用
        # ...
        self._events.append(RecommendationGenerated(...))
    
    def exclude_purchased(self, purchased_ids):
        """購入済み商品を除外する"""
        self._items = [i for i in self._items if i.product_id not in purchased_ids]
    
    @property
    def domain_events(self):
        return list(self._events)
    
    def clear_events(self):
        self._events.clear()
```

**値オブジェクトの実装パターン：**
```python
from dataclasses import dataclass

@dataclass(frozen=True)
class RecommendationScore:
    """推薦スコア値オブジェクト（不変）"""
    product_id: str
    score: float
    reason: RecommendationReason
    
    def __post_init__(self):
        if not 0.0 <= self.score <= 1.0:
            raise ValueError(f"Score must be between 0.0 and 1.0, got {self.score}")
```

**リポジトリインターフェース：**
```python
from abc import ABC, abstractmethod

class RecommendationRepository(ABC):
    """リポジトリインターフェース（ドメインレイヤー）"""
    
    @abstractmethod
    def find_by_customer(self, customer_id, context) -> Recommendation | None:
        pass
    
    @abstractmethod
    def save(self, recommendation: Recommendation) -> None:
        pass
```

### BDDフレーバー

Given-When-Thenシナリオがそのまま受け入れテストになるコード構造。

**シナリオ駆動のテストファースト：**
```python
# tests/acceptance/features/test_stock_threshold.py

def test_single_product_below_threshold():
    """シナリオ1: 単一商品の在庫が閾値を下回る"""
    # Given: 商品Aの在庫閾値が100個に設定されている
    product = create_product("A", threshold=100)
    # And: 現在の在庫数が105個である
    set_stock(product, 105)
    
    # When: 出庫により在庫数が95個に減少する
    result = process_shipment(product, quantity=10)
    
    # Then: 在庫閾値割れイベントが生成される
    assert result.events_contain(ThresholdBreachedEvent)
    # And: イベントには商品ID、現在在庫数、閾値、変動量が含まれる
    event = result.get_event(ThresholdBreachedEvent)
    assert event.product_id == "A"
    assert event.current_stock == 95
    assert event.threshold == 100
```

**コンポーネントはシナリオを満たすために逆算して実装する。**

### TDDフレーバー

Red-Green-Refactorサイクルを意識したコード生成。

**テストファーストの順序：**
1. 受け入れ基準からテストケースを先に生成（Red）
2. テストを通過する最小限のコードを生成（Green）
3. リファクタリングを提案（Refactor）

```python
# 1. Red: まずテストを書く
def test_get_recommendations_returns_at_least_3():
    engine = RecommendationEngine(mock_repo, mock_filter)
    result = engine.recommend(customer_id="C001", context="page")
    assert len(result.items) >= 3

# 2. Green: テストを通す最小限の実装
# 3. Refactor: 重複排除、パターン適用
```

---

## コード生成の品質基準

### 命名規則
- クラス名: ドメインモデルの用語をそのまま使用（PascalCase）
- メソッド名: 振る舞いの表に記載された名前をそのまま使用（snake_case）
- 変数名: ドメインの文脈で意味が明確な名前

### エラーハンドリング
- ドメインレイヤー: ドメイン固有の例外を定義・使用
- アプリケーションレイヤー: ドメイン例外をキャッチしてユースケース例外に変換
- インフラレイヤー: インフラ例外をキャッチしてアプリケーション例外に変換

```python
# domain/exceptions.py
class InsufficientRecommendationsError(Exception):
    """レコメンデーション結果が最低件数を満たさない"""
    pass

class CustomerProfileNotFoundError(Exception):
    """買い物客プロファイルが見つからない"""
    pass
```

### 依存性注入
すべての外部依存はコンストラクタで注入する。テスト時にモック差し替えが容易になる。

```python
class RecommendationEngine:
    def __init__(
        self,
        profile_repo: CustomerProfileRepository,
        recommendation_repo: RecommendationRepository,
        collaborative_filter: CollaborativeFilter,
        popularity_fallback: PopularityFallback,
    ):
        self._profile_repo = profile_repo
        # ...
```

---

## ブラウンフィールドのコード変更

### 変更の原則
1. **既存テストを先に実行** — 変更前にグリーンであることを確認
2. **拡張モデルに従う** — `_extension_model.md` の変更仕様に厳密に従う
3. **既存パターンを踏襲** — 命名規則、レイヤー構造、エラーハンドリング方式を既存に合わせる
4. **後方互換性を維持** — 既存APIのシグネチャ変更は避ける。新規エンドポイントを追加
5. **変更後に既存テスト + 新規テストの両方を実行** — リグレッションなしを確認
