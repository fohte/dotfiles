---
name: pencil-design
description: 'Guide for working with .pen files using the Pencil MCP server. TRIGGER when: about to call any mcp__pencil__* tool, designing/editing/reviewing .pen files, working with the Pencil desktop app, user mentions pencil/.pen files/canvas design tasks, or a .pen file is open in the editor or referenced in the conversation. IMPORTANT: This skill MUST be loaded BEFORE calling any mcp__pencil__* tool.'
---

# Pencil Design

Pencil MCP サーバーを使って .pen ファイルのデザイン作業を行うためのワークフローとガイドライン。

## 重要な制約: 保存は GUI アプリでのみ可能

**Pencil MCP では .pen ファイルの保存ができない。** MCP 経由で行った変更はアプリのメモリ上にのみ存在し、ファイルシステムには反映されない。

- batch_design で変更を加えた後、**必ずユーザーに Pencil GUI アプリで保存 (Cmd+S) するよう伝える**こと
- 「ファイルに変更が反映されていない」「git diff に出ない」場合は、まず GUI での保存漏れを疑う
- 保存が必要なタイミング:
    - デザイン変更の一区切りごと
    - スクリーンショットを export_nodes で書き出す前
    - git commit する前

**やりがちなミス:** batch_design で変更 → export_nodes や git 操作 → ファイルが更新されていない → 原因がわからず迷走。これは GUI 保存をしていないだけ。変更後は必ずユーザーに保存を依頼する。

## ワークフロー

### 1. 現状把握

```
get_editor_state(include_schema: true)  -- スキーマと現在の状態を取得
```

- 初回は必ず `include_schema: true` でスキーマを取得する
- エディタが開いていない場合は `open_document` で開く

### 2. 構造の理解

```
batch_get(filePath, patterns/nodeIds)   -- ノード構造を調査
snapshot_layout(filePath)               -- レイアウト状況を確認
```

- まず全体構造 (トップレベルノード) を把握してから、必要な部分を深掘りする
- `readDepth` は小さい値 (1-2) から始める。3 以上は大量データになるため慎重に

### 3. デザイン変更

```
batch_design(filePath, operations)      -- ノードの挿入・更新・削除
```

- 1 回の呼び出しは最大 25 操作に抑える
- 大きな変更は論理的なセクションに分割して複数回に分ける

### 4. 確認

```
get_screenshot(filePath, nodeId)        -- 変更結果を視覚的に確認
snapshot_layout(filePath, problemsOnly: true)  -- レイアウト問題を検出
```

- **変更後は必ずスクリーンショットで確認する**。データ上は正しくても視覚的に壊れていることがある
- `problemsOnly: true` でクリッピングやオーバーラップを検出できる

### 5. 保存の依頼

変更が完了したら、ユーザーに GUI アプリでの保存を依頼する。

## キャンバスのレイアウト管理

### コンポーネントの重なり防止

コンポーネントのサイズを変更した場合、**隣接するコンポーネントの位置も調整が必要**。これは自動では行われない。

**重要: `snapshot_layout(problemsOnly: true)` はかぶりを検出しない。** このツールはクリッピング等の問題のみ検出する。トップレベルフレーム同士のかぶりは**自分で座標を計算して検証する必要がある**。

**かぶり検証の手順:**

1. `snapshot_layout(maxDepth: 0)` で全トップレベルノードの x, y, width, height を取得する
2. **同じ x 座標列にあるノードをグループ化する** (x 範囲が重なるもの同士)
3. 各グループ内で、y 座標順にソートし、各ノードの底辺 (y + height) が次のノードの y 座標を超えていないか計算する
4. かぶりがあれば、下のノードを底辺 + マージン (100px 程度) の位置に移動する
5. 移動した場合、そのさらに下のノードも連鎖的にずらす

**フレーム内にコンテンツを追加してフレームの高さが増えた場合も、同じ検証が必要。** fit_content のフレームは子の追加で自動的に高さが変わるため、追加のたびにかぶりを再確認すること。

**例:** 高さ 10px のコンポーネント A (Y=0) の下に、マージン 10px を挟んでコンポーネント B (Y=20) がある場合:

- A の高さを 30px に変更 → 増分は 20px
- B の Y 座標を 20 + 20 = 40 に更新する
- さらに B の下にコンポーネントがあれば、それも同様にずらす

### 新しいコンポーネントの配置

- `find_empty_space_on_canvas` を使って空きスペースを探す
- 既存コンポーネントとの適切なマージンを確保する

## コンポーネントの共通化

### reusable コンポーネントの作成を積極的に行う

同じまたは似たデザインパターンが 2 箇所以上で使われる場合、**reusable コンポーネントとして共通化する**。

**やるべきこと:**

- ボタン、カード、リストアイテムなど繰り返されるパターンはコンポーネント化する
- コンポーネントのインスタンス (`ref` タイプ) を使って配置する
- デザインの一貫性を保つため、コピペではなくコンポーネント参照を使う

**やってはいけないこと:**

- 同じ構造のノードを複数箇所にコピペする
- 似たデザインだが微妙に異なるノードを手動で複製する (統一すべき差異が生まれる)

### コンポーネント化の手順

1. `batch_get(patterns: [{reusable: true}])` で既存の reusable コンポーネントを確認
2. 共通化すべきパターンがあれば、1 つを reusable コンポーネントとして定義
3. 他の箇所は `ref` タイプのインスタンスで置き換える
4. インスタンスごとの差分は、インスタンスパスを使って `U()` でカスタマイズする

## ツールの使い分け

| ツール                                     | 用途                                                 |
| ------------------------------------------ | ---------------------------------------------------- |
| `get_editor_state`                         | 作業開始時。スキーマ取得、現在の選択状態の確認       |
| `open_document`                            | .pen ファイルを開く、または新規作成                  |
| `batch_get`                                | ノード構造の調査。パターン検索や ID 指定での読み取り |
| `batch_design`                             | ノードの挿入・更新・削除・移動・コピー               |
| `get_screenshot`                           | 変更結果の視覚的確認                                 |
| `snapshot_layout`                          | レイアウトの数値確認、問題検出                       |
| `find_empty_space_on_canvas`               | 新規コンポーネントの配置場所を探す                   |
| `export_nodes`                             | PNG/JPEG/PDF への書き出し                            |
| `get_guidelines`                           | デザインガイドラインの取得 (トピック別)              |
| `get_style_guide_tags` / `get_style_guide` | デザインインスピレーション取得                       |
| `get_variables` / `set_variables`          | テーマ変数の管理                                     |
| `replace_all_matching_properties`          | プロパティの一括置換                                 |
| `search_all_unique_properties`             | 使用中プロパティの調査                               |

## .pen ファイルの読み書きに関する注意

- .pen ファイルの中身は暗号化されている。`Read` や `Grep` ツールでは読めない
- 必ず pencil MCP ツール (`batch_get` など) を使うこと

## デザインガイドラインの活用

新規デザインやスクリーン作成時は、適切なガイドラインを取得する:

- `get_guidelines(topic: "web-app")` -- Web アプリのデザイン
- `get_guidelines(topic: "mobile-app")` -- モバイルアプリのデザイン
- `get_guidelines(topic: "landing-page")` -- ランディングページ
- `get_guidelines(topic: "design-system")` -- デザインシステムのコンポーネント活用
- `get_guidelines(topic: "slides")` -- プレゼンテーション

スタイルの方向性を決める場合は `get_style_guide_tags` → `get_style_guide` の順で取得する。
