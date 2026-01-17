---
name: create-pr
description: Use this skill when creating a Pull Request. This skill provides the workflow for drafting, reviewing, and submitting PRs using a ai pr-draft command.
---

# Create PR

変更を push した後、以下の手順で PR を作成する。

## 1. PR body のドラフトファイルを作成する

`echo` コマンドを使用して、PR の説明のドラフトを `a ai pr-draft new` コマンドに渡す。

**重要:** このドラフトは **常に日本語で書くこと**（public repo、private repo に関わらず）。

```bash
echo "## Why

- from: <関連 Issue/PR の URL があれば記載>
- <何が問題なのか、または何を実現したいのかを 1 文で述べる>
  - <根拠・原因・背景があれば補足>

## What

- <変更によって何が変わるかを記述 (実装の詳細ではなく効果を書く)>" | a ai pr-draft new --title "PRタイトル"
```

ドラフトファイルは `/tmp/pr-body-draft/<owner>/<repo>/<branch>.md` に自動的に作成される。以降のコマンドではファイルパスの指定は不要。

### タイトルの生成ガイドライン

- **簡潔に**: 50 文字以内で変更内容を要約
- **現在形の命令形**: 「Add ...」「Fix ...」「Update ...」など
- **日本語で生成**: body と同様に日本語で書く（public repo の場合、翻訳はユーザーが `steps.ready-for-translation: true` にした後に行う）
- **効果を書く、実装を書かない**: 「何をするか」ではなく「何が解決されるか/何ができるようになるか」を書く
    - ❌ `minimumReleaseAge チェックをスキップする` (実装詳細)
    - ✅ `lockFileMaintenance の automerge が動作するようにする` (効果)

#### release-please を使用しているリポジトリの場合

リポジトリに `release-please-config.json` または `.release-please-manifest.json` が存在する場合は、**Conventional Commits** 形式を使用する:

- **フォーマット**: `<type>(<scope>): <description>`

##### type 選択フロー（必須）

**重要:** type を選択する前に、必ず以下のフローに従って判断すること。

```
Q1: この変更はエンドユーザー（ライブラリ利用者/アプリ利用者）に影響するか?
    │
    ├─ YES → Q2: 新機能か、既存機能の修正か?
    │         ├─ 新機能 → feat (minor bump)
    │         └─ 既存機能の修正 → fix (patch bump)
    │
    └─ NO → Q3: 何を変更したか?
              ├─ テストのみ → test (bump なし)
              ├─ ドキュメントのみ → docs (bump なし)
              ├─ コードの内部構造（挙動変更なし）→ refactor (bump なし)
              ├─ フォーマット/スタイルのみ → style (bump なし)
              ├─ パフォーマンス改善（挙動変更なし）→ perf (bump なし)
              ├─ ビルドシステム/依存関係 → build (bump なし)
              ├─ CI 設定 → ci (bump なし)
              └─ その他のツール設定 → chore (bump なし)
```

**よくある間違い:**

- ❌ テストを「修正」したから `fix` → テストの修正はユーザーに影響しないので `test`
- ❌ CI を「直した」から `fix` → CI/ビルドの修正はユーザーに影響しないので `chore`
- ❌ リファクタリングで「バグを防いだ」から `fix` → 実際にバグが発生していなければ `refactor`
- ❌ ドキュメントの「誤りを修正」したから `fix` → ドキュメントは `docs`

**type 一覧:**

| type       | バージョン | 用途                                     |
| ---------- | ---------- | ---------------------------------------- |
| `feat`     | minor bump | 新機能追加（ユーザーに新しい価値を提供） |
| `fix`      | patch bump | バグ修正（ユーザーが遭遇する問題を解決） |
| `docs`     | bump なし  | ドキュメントのみの変更                   |
| `style`    | bump なし  | フォーマットなど（機能変更なし）         |
| `refactor` | bump なし  | リファクタリング（機能変更なし）         |
| `perf`     | bump なし  | パフォーマンス改善                       |
| `test`     | bump なし  | テストの追加・修正                       |
| `build`    | bump なし  | ビルドシステムや依存関係の変更           |
| `ci`       | bump なし  | CI 設定の変更                            |
| `chore`    | bump なし  | その他のツール設定・雑務                 |

- **description の書き方**:
    - **動詞形で書く**: 名詞形ではなく「〜する」「〜できるようにする」のような動詞形で書く
    - **type との二重表現を避ける**: `fix` type なら「修正」、`feat` type なら「追加」を description に含めない
        - Bad: `fix(api): エラーハンドリングを修正` (fix + 修正 = 二重表現)
        - Good: `fix(api): エラーハンドリングが動作するようにする`
    - **技術的に正確な表現を使う**: 冗長・意味不明な表現を避ける
        - Bad: `tar.gz の gzip 解凍` (tar.gz は gzip 圧縮された tar なので冗長)
        - Good: `gzip 解凍できるようにする`

- **例**:
    - `feat(auth): ログイン機能を実装する`
    - `fix(api): エラーレスポンスが正しく返るようにする`
    - `docs(readme): インストール手順を更新する`

#### release-please を使用していないリポジトリの場合

シンプルな形式を使用:

- **フォーマット**: `<scope>: <description>`
- **description は動詞形で書く** (上記の「description の書き方」を参照)
- **例**:
    - 機能追加: `auth: ログイン機能を実装する`
    - バグ修正: `api: エラーレスポンスが正しく返るようにする`
    - リファクタリング: `utils: ヘルパー関数を整理する`

注意: Markdown のコードブロックにバッククォートを含める場合、シェルのクォートの種類によってエスケープが必要。

```bash
# double quote のときは \` でエスケープ
echo "use \`gh\` command"

# single quote のときは escape 不要
echo 'use `gh` command'
```

### Frontmatter について

作成されるファイルには以下の YAML frontmatter が含まれる:

**Private repo の場合:**

```yaml
---
title: 'PRタイトル'
steps:
    submit: false
---
```

**Public repo の場合:**

```yaml
---
title: 'PRタイトル'
steps:
    ready-for-translation: false
    submit: false
---
```

- `title`: PR のタイトル（submit 時に使用される）
- `steps.ready-for-translation`: (public repo のみ) ドラフト承認フラグ。true になったら翻訳を実行する。public repo では翻訳は**必須**であり、submit 時に日本語が含まれているとエラーになる
- `steps.submit`: true にするとエディタ終了時にファイルのハッシュが保存される。submit 時にハッシュが一致しないと失敗する（改ざん防止）

### 注意事項

- **Why/What のみ記述**: それ以外のセクション (「期待される効果」「参考」など) は書かない
- **コード要素はバッククォートで囲む**: ファイル名、関数名、変数名、コマンド名などは必ず `` ` `` で囲む
    - Good: `config.json` を更新、`handleError` 関数を追加
    - Bad: config.json を更新、handleError 関数を追加

### Why セクションの書き方

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

### What セクションの書き方

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

## 2. 人間に PR の説明をレビューしてもらう

`a ai pr-draft review` コマンドを実行して、Wezterm の新しいウィンドウで Neovim を開き、ユーザーに直接編集してもらう。

```bash
a ai pr-draft review
```

**重要:** このコマンドは非同期で実行されるため、コマンドが即座に完了してもユーザーはまだ編集中である。ユーザーがレビューを完了して明示的に指示するまで、次のステップには進まないこと。

## 3. ユーザーの指示に応じた対応

ユーザーからの指示があったら、draft ファイルを読み込んで状態を確認し、以下のように対応する。

**重要:** public repo では翻訳は**必須**である。`steps.ready-for-translation` は「翻訳するかしないか」の選択ではなく、「ドラフトの内容が承認され、翻訳の準備ができたか」を示すフラグ。

### 修正指示の場合（「fix」「修正」など）

内容の修正のみを行う。**翻訳は行わない。**
修正後は再度 `a ai pr-draft review` を実行し、次の指示を待つ。

### ドラフト承認後の翻訳（`steps.ready-for-translation: true` かつ日本語含む）

ユーザーがドラフトの内容を承認し、`steps.ready-for-translation: true` に変更した場合:

1. title と body を英語に翻訳する
2. `steps.submit: false` に変更する（翻訳によりハッシュが無効になるため）
3. ファイルを上書き保存する
4. 再度 `a ai pr-draft review` を実行して、ユーザーに翻訳内容を確認してもらう
5. ユーザーがレビューを完了して明示的に指示するまで待機する

**翻訳時の注意:**

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

**注意:** すでに英語に翻訳済み（日本語が含まれていない）の場合は、再翻訳しない。

### Private repo の場合（`steps.ready-for-translation` キーが存在しない）

翻訳は不要。ユーザーが `steps.submit: true` にしたら submit に進む。

## 4. `a ai pr-draft submit` で PR を作成

```bash
a ai pr-draft submit [--base main]
```

frontmatter の `title` が PR タイトルとして、body 部分が PR 本文として使用される。

**注意:** submit は以下の条件をすべて満たす場合のみ成功する:

- `.lock` ファイルがない（レビュー完了）
- `.approve` ファイルがある（`steps.submit: true` でエディタを終了した）
- ファイルのハッシュが `.approve` と一致する（承認後に改ざんされていない）
- public repo の場合、title と body に日本語が含まれていない

## 5. CI 実行を監視

`gh pr checks --watch` コマンドを使用して CI チェックを監視します。
CI が成功したら次のステップに進みます。失敗した場合は、問題を調査・修正して再度プッシュしてください。

## 6. Gemini Code Assist レビューを待機（fohte リポジトリのみ）

**対象:** リポジトリの owner が `fohte` の場合のみこのステップを実行する。

CI が成功したら、`a ai review wait` コマンドを使用して Gemini Code Assist のレビュー完了を待機します（初回レビューは PR 作成時に自動でリクエストされる）。

```bash
a ai review wait
```

レビューが完了したら、`check-pr-review` skill を使用してレビュー内容を確認し、指摘事項があれば対応してください。
