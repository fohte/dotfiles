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

- なぜこのPRが必要なのかの、目的、背景、動機を説明

## What

- この PR が merge されたら何が変わるのかを、個々のコミットではなく全体的な影響を現在形で記述" | a ai pr-draft new --title "PRタイトル"
```

ドラフトファイルは `/tmp/pr-body-draft/<owner>/<repo>/<branch>.md` に自動的に作成される。以降のコマンドではファイルパスの指定は不要。

### タイトルの生成ガイドライン

- **簡潔に**: 50 文字以内で変更内容を要約
- **現在形の命令形**: 「Add ...」「Fix ...」「Update ...」など
- **日本語で生成**: body と同様に日本語で書く（public repo の場合、翻訳はユーザーが `steps.ready-for-translation: true` にした後に行う）

#### release-please を使用しているリポジトリの場合

リポジトリに `release-please-config.json` または `.release-please-manifest.json` が存在する場合は、**Conventional Commits** 形式を使用する:

- **フォーマット**: `<type>(<scope>): <description>`
- **type の選択**:

    **バージョンが上がる type（リリースに含まれる）:**
    - `feat`: 新機能追加 → **minor** バージョンアップ (例: 1.2.0 → 1.3.0)
    - `fix`: バグ修正 → **patch** バージョンアップ (例: 1.2.0 → 1.2.1)

    **バージョンが上がらない type（リリースに含まれない）:**
    - `docs`: ドキュメントのみの変更
    - `style`: フォーマットなど（機能変更なし）
    - `refactor`: リファクタリング（機能変更なし）
    - `perf`: パフォーマンス改善
    - `test`: テストの追加・修正
    - `chore`: ビルドプロセスやツールの変更

    **判断の指針:** PR を作成する際は、この変更がユーザーに影響を与えるかどうかを考慮し、バージョンを上げるべきかどうかを明示的に判断すること。内部的なリファクタリングでもユーザーに見える改善がある場合は `fix` や `feat` を検討する

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
- **Why には関連 issue/PR のリンクを含める**: 詳細は issue に記載されているため
- **簡潔に**: 過剰な数値データ、技術的詳細、Markdown 装飾は避ける
- **コード要素はバッククォートで囲む**: ファイル名、関数名、変数名、コマンド名などのコード要素は必ず `` ` `` で囲むこと
    - Good: `config.json` を更新、`handleError` 関数を追加
    - Bad: config.json を更新、handleError 関数を追加

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
- **「〜できるようにする」の訳し方**:
    - `enable` は「有効化する」のニュアンスが強いので避ける
    - `support` や `allow` の方が「〜できるようにする」に近い
    - 例: 「gzip 解凍できるようにする」→ `support gzip decompression`
- **type との二重表現を英語でも避ける**: `fix: fix ...` のような表現にしない

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

`gh pr checks --watch`コマンドを使用してCIチェックを監視します。
CI が成功したら完了です。失敗した場合は、問題を調査・修正して再度プッシュしてください。
