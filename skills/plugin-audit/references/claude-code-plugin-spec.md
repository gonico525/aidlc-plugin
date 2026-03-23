# Claude Code Plugin 公式仕様リファレンス

## 調査日: 2026-03-23

このファイルは Claude Code Plugin の公式仕様をまとめたものである。
監査スキル実行時に最新情報で更新される。

---

## 1. plugin.json

プラグインマニフェスト。`.claude-plugin/plugin.json` に配置する。

### 必須フィールド
| フィールド | 型 | 説明 |
|-----------|-----|------|
| `name` | string | プラグイン名 |
| `version` | string | セマンティックバージョン |
| `description` | string | プラグインの説明 |

### 推奨フィールド
| フィールド | 型 | 説明 |
|-----------|-----|------|
| `author` | object | `{ "name": "..." }` |
| `license` | string | ライセンス識別子 |
| `repository` | string | リポジトリURL |
| `homepage` | string | ホームページURL |
| `keywords` | string[] | 検索用キーワード |

### コンポーネントパス
| フィールド | 型 | 説明 |
|-----------|-----|------|
| `skills` | string | スキルディレクトリパス (例: `"./skills/"`) |
| `agents` | string | エージェントディレクトリパス (例: `"./agents/"`) |
| `hooks` | string | フック設定ファイルパス (例: `"./hooks/hooks.json"`) |

---

## 2. SKILL.md フロントマター

各スキルは `skills/<name>/SKILL.md` に定義する。

### フロントマターフィールド
| フィールド | 必須 | 型 | 説明 |
|-----------|------|-----|------|
| `name` | ○ | string | スキル名 |
| `description` | ○ | string | スキルの説明。トリガー判定に使用される |
| `allowed-tools` | △ | string | 許可ツール（カンマ区切り） |
| `model` | △ | string | 使用モデル (`sonnet`, `opus`, `haiku`) |
| `effort` | △ | string | 推論レベル (`medium`, `high`, `max`) |

### description のベストプラクティス
- 2-3 行以内に収める
- トリガー条件は本文の `## トリガー条件` セクションに記述する
- LLM がスキル選択時に参照するため、明確で具体的に書く

### 利用可能なツール名
Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch, Agent, TodoWrite, AskUserQuestion

### 本文の推奨構造
```
## トリガー条件
## このスキルの目的
## 前提知識
## ワークフロー
```

---

## 3. エージェント .md フロントマター

各エージェントは `agents/<name>.md` に定義する。

### フロントマターフィールド
| フィールド | 必須 | 型 | 説明 |
|-----------|------|-----|------|
| `name` | ○ | string | エージェント名 |
| `description` | ○ | string | エージェントの説明 |
| `model` | △ | string | 使用モデル (`sonnet`, `opus`, `haiku`) |
| `effort` | △ | string | 推論レベル |
| `maxTurns` | △ | number | 最大ターン数 |
| `tools` | △ | string | 許可ツール（カンマ区切り） |
| `disallowedTools` | △ | string | 拒否ツール（カンマ区切り） |

### ツール制限のベストプラクティス
- **最小権限の原則**: 必要最低限のツールのみ許可
- `WebFetch`, `WebSearch` は外部通信のため原則拒否
- 読み取り専用エージェントは `Write`, `Edit`, `Bash` を拒否

---

## 4. hooks.json

Claude Code ライフサイクルフック。`hooks/hooks.json` に定義する。

### 構造
```json
{
  "hooks": {
    "{EventType}": [
      {
        "matcher": "{ToolName|Pattern}",
        "hooks": [
          {
            "type": "command" | "prompt",
            "command": "{shell command}",
            "prompt": "{prompt text}"
          }
        ]
      }
    ]
  }
}
```

### サポートされるイベントタイプ
| イベント | タイミング |
|---------|----------|
| `PreToolUse` | ツール実行前 |
| `PostToolUse` | ツール実行後 |
| `Stop` | セッション終了時 |
| `SubagentStop` | サブエージェント完了時 |

### 変数
- `$TOOL_NAME` — 実行されたツール名
- `$FILE_PATH` — 対象ファイルパス（ファイル操作ツールの場合）

---

## 5. 更新履歴

| 日付 | 内容 |
|------|------|
| 2026-03-23 | 初版作成。公式ドキュメントと実地調査に基づく |
