#!/usr/bin/env bash
# AI-DLC 初期セットアップスクリプト
# aidlc-docs/ フォルダ構造と manifest.md テンプレートを作成する。
# 既存ファイルは上書きしない（冪等）。

set -euo pipefail

BASE_DIR="aidlc-docs"

# フォルダ構造の作成
dirs=(
  "$BASE_DIR/plans"
  "$BASE_DIR/requirements"
  "$BASE_DIR/story-artifacts"
  "$BASE_DIR/design-artifacts/domain-models"
  "$BASE_DIR/design-artifacts/logical-designs"
  "$BASE_DIR/design-artifacts/adrs"
  "$BASE_DIR/design-artifacts/units"
  "$BASE_DIR/handoffs"
  "$BASE_DIR/reports"
)

for dir in "${dirs[@]}"; do
  mkdir -p "$dir"
done

# manifest.md テンプレートの作成（存在しない場合のみ）
MANIFEST="$BASE_DIR/manifest.md"
if [ ! -f "$MANIFEST" ]; then
  cat > "$MANIFEST" << 'TEMPLATE'
# AI-DLC マニフェスト

## メタ
- 意図: {高レベルの意図を1文で}
- フレーバー: {DDD / BDD / ストーリーベース}
- 開発種別: {グリーンフィールド / ブラウンフィールド}
- 作成日: {YYYY-MM-DD}
- 最終更新: {YYYY-MM-DD}

## 成果物台帳

### requirements（要件）
| ID | ファイル | 生成元 | ステータス | 最終更新 |
|----|---------|--------|----------|---------|

### stories（ストーリー）
| ID | ファイル | 生成元 | ステータス | 最終更新 |
|----|---------|--------|----------|---------|

### units（ユニット）
| ID | ファイル | 生成元 | ステータス | 最終更新 |
|----|---------|--------|----------|---------|

### designs（設計）
| ID | ファイル | 生成元 | ステータス | 最終更新 |
|----|---------|--------|----------|---------|

### code（コード）
| ID | ファイル/ディレクトリ | 生成元 | ステータス | 最終更新 |
|----|-------------------|--------|----------|---------|

### reports（レポート）
| ID | ファイル | 生成元 | ステータス | 最終更新 |
|----|---------|--------|----------|---------|

### plans（計画）
| ID | ファイル | 生成元 | ステータス | 最終更新 |
|----|---------|--------|----------|---------|
TEMPLATE
  echo "Created $MANIFEST"
else
  echo "$MANIFEST already exists, skipping"
fi

# prompts.md の作成（存在しない場合のみ）
PROMPTS="$BASE_DIR/prompts.md"
if [ ! -f "$PROMPTS" ]; then
  cat > "$PROMPTS" << 'TEMPLATE'
# AI-DLC 指示記録
TEMPLATE
  echo "Created $PROMPTS"
else
  echo "$PROMPTS already exists, skipping"
fi

echo "AI-DLC initialization complete."
