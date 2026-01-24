---
name: create-pr
description: Use this skill when creating a Pull Request. This skill provides the workflow for drafting, reviewing, and submitting PRs using a ai pr-draft command.
---

# Create PR

変更を push した後、以下の手順で PR を作成する。

## 0. 状態確認時の注意

**重要:** PR に含まれる変更を確認する際は、ローカルの `master` ブランチではなく、必ず `origin/master` と比較すること。

```bash
# 正しい (リモートの最新状態と比較)
git diff origin/master...HEAD
git log origin/master..HEAD

# 間違い (ローカルの master が古いと不要な差分が含まれる)
git diff master...HEAD
git log master..HEAD
```

ローカルの master を pull していない場合、release-please が生成した CHANGELOG.md やバージョン更新のコミットが差分に含まれてしまうため。

## 1. PR body のドラフトファイルを作成する

**まず [writing-guide.md](writing-guide.md) を読み込むこと。** タイトルと description の書き方ルールが定義されている。

!`[ -f release-please-config.json ] || [ -f .release-please-manifest.json ] && echo "**また [release-please-guide.md](release-please-guide.md) も読み込むこと。** このリポジトリは release-please を使用しているため、Conventional Commits 形式を使用する必要がある。"`

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

注意: Markdown のコードブロックにバッククォートを含める場合、シェルのクォートの種類によってエスケープが必要。

```bash
# double quote のときは \` でエスケープ
echo "use \`gh\` command"

# single quote のときは escape 不要
echo 'use `gh` command'
```

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

翻訳時の注意事項は [writing-guide.md](writing-guide.md) の「翻訳時の注意」セクションに従うこと。

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
