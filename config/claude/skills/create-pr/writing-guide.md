# PR タイトルと description の書き方ガイド

このドキュメントは PR のタイトルと body (Why/What セクション) の書き方を定義する。

## 基本ルール

- **Why/What のみ記述**: それ以外のセクション (「期待される効果」「参考」など) は書かない
- **コード要素はバッククォートで囲む**: ファイル名、関数名、変数名、コマンド名などは必ず `` ` `` で囲む
    - Good: `config.json` を更新、`handleError` 関数を追加
    - Bad: config.json を更新、handleError 関数を追加

## タイトルの生成ガイドライン

- **簡潔に**: 50 文字以内で変更内容を要約
- **現在形の命令形**: 「Add ...」「Fix ...」「Update ...」など
- **日本語で生成**: body と同様に日本語で書く（public repo の場合、翻訳はユーザーが `steps.ready-for-translation: true` にした後に行う）
- **効果を書く、実装を書かない**: 「何をするか」ではなく「何が解決されるか/何ができるようになるか」を書く
    - ❌ `minimumReleaseAge チェックをスキップする` (実装詳細)
    - ✅ `lockFileMaintenance の automerge が動作するようにする` (効果)

!`[ -f release-please-config.json ] || [ -f .release-please-manifest.json ] && cat ~/.claude/skills/create-pr/release-please-guide.md`

### release-please を使用していないリポジトリの場合

シンプルな形式を使用:

- **フォーマット**: `<scope>: <description>`
- **description は動詞形で書く** (上記の「description の書き方」を参照)
- **例**:
    - 機能追加: `auth: ログイン機能を実装する`
    - バグ修正: `api: エラーレスポンスが正しく返るようにする`
    - リファクタリング: `utils: ヘルパー関数を整理する`

## Why セクションの書き方

- **Issue リンクを先頭に**: `- from: <URL>` 形式で関連 Issue/PR へのリンクを記載 (あれば)
- **問題/目的を最初に**: 「何が問題か」または「何を実現したいか」を最初の箇条書きで述べる
- **根拠・背景はインデントで補足**: 問題の原因、背景、判断理由は子要素として記載
- **根拠は引用文とリンクをセットで記載**: リンクだけでなく該当箇所を引用し、リンク先が変更されても追跡可能にする
    - **引用は原文をそのまま使用する**: 勝手に要約・省略・変更してはならない。必ずドキュメントから正確にコピーすること
    - 引用文が長い場合は、根拠として必要な部分を正確に抜粋する

**引用の書式:**

```markdown
> 引用文 (原文をそのままコピー)
> [ドキュメント名](URL)
```

## What セクションの書き方

**原則: 「What (何を)」を書く。「How (どのように)」は diff で見えるので書かない。**

- **Title と What の役割分担**: Title は効果を一言で、What は Title をもう少し具体的に説明する (ただし How ではない)
- **「何が変わるか」を書く**: 変更の効果、ユーザー/システムへの影響
- **「どこをどう変えたか」は書かない**: ファイルパス、行番号、具体的なコード変更

**Title と What の例:**

```markdown
Title: lockFileMaintenance の automerge が動作するようにする

## What

- `lockFileMaintenance` に対して `minimumReleaseAge` のチェックを無効化し、リリースタイムスタンプが取得できない場合でも automerge が実行されるようにする
```

**抽象度の例:**

| ✅ 適切 (What)                         | ❌ 詳細すぎ (How)                                       |
| -------------------------------------- | ------------------------------------------------------- |
| API レスポンスにページネーションを追加 | `getUsers` 関数の戻り値に `nextCursor` フィールドを追加 |
| エラー時のリトライ処理を追加           | `fetch` を `while` ループで囲んで 3 回までリトライ      |

## 英語ライティングガイドライン

翻訳時および英語で記述する際の一般的なルール。

### 文の始め方

- **「Want to...」「Need to...」で文を始めない**: 命令形または能動態を使う
    - ❌ `Need to enforce proper error handling`
    - ✅ `Enforce proper error handling`
- **「When ...」で始めるのは OK**: 状況を説明する副詞節として自然。ただし、問題を直接述べる方がより明快な場合もある
    - OK: `When using this library, memory leaks may occur`
    - より直接的: `This library causes memory leaks under certain conditions`

### Why セクションでの書き方

- **問題の主体を先に持ってくる**: 「When X happens, Y occurs」より「Y tends to occur (in X situations)」の方が明快
    - ❌ `When writing code with AI tools, panic! tends to be used casually`
    - ✅ `panic! and unwrap are often used casually in AI-generated code`

### 自然な英語表現

- **直訳を避け、意図を伝える**: 日本語の構造をそのまま英語にせず、英語として自然な表現に言い換える
    - ❌ `Fix existing violations and add annotations` (並列に見えるが実際は手段と目的)
    - ✅ `Fix existing violations by adding annotations` (因果関係が明確)
- **冗長な表現を避ける**: 同じ意味を繰り返さない
    - ❌ `in order to` → ✅ `to`
    - ❌ `make sure to` → ✅ `ensure` or just use imperative

### その他の注意

- **「etc.」の使用を避ける**: 文中での使用はカジュアルすぎる。「or similar tools」「and related features」などを使う
    - ❌ `Claude Code etc.`
    - ✅ `Claude Code or similar tools`

## 翻訳時の注意

public repo では翻訳が必須。翻訳時は以下に注意すること。

- **日本語の意図を正確に反映する**: 直訳ではなく、意図を汲んだ自然な英語にする
- **type との二重表現を英語でも避ける**: `fix: fix ...` のような表現にしない
- **`fix` type の description では解決策を述べる**:
    - `support` は新機能追加のニュアンスが強いので `fix` type では避ける
    - 事実の列挙 (「〜が失敗していた」) ではなく、何を変えて解決したかを述べる
    - Bad: `fix(wm): support \`wm new\` on macOS` (support は feat 向き)
    - Bad: `fix(wm): \`wm new\` failing on macOS` (事実の列挙、解決策が見えない)
    - Good: `fix(wm): use cache directory instead of state directory for macOS compatibility`
- **`feat` type の description では「〜できるようにする」の訳し方に注意**:
    - `enable` は「有効化する」のニュアンスが強いので避ける
    - `support` や `allow` の方が「〜できるようにする」に近い
    - 例: 「gzip 解凍できるようにする」→ `support gzip decompression`
