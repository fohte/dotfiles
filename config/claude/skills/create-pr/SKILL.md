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

**まず ~/.claude/skills/create-pr/writing-guide.md を読み込むこと。** タイトルと description の書き方ルールが定義されている。

!`claude-skill-check is-public && echo "**また ~/.claude/skills/create-pr/public-repo-guide.md も読み込むこと。** このリポジトリは public であるため、英語ライティングガイドラインと翻訳ルールに従う必要がある。" || true`

!`[ -f release-please-config.json -o -f .release-please-manifest.json ] && echo "**また ~/.claude/skills/create-pr/release-please-guide.md も読み込むこと。** このリポジトリは release-please を使用しているため、Conventional Commits 形式を使用する必要がある。" || true`
!`[ -f release-please-config.json -o -f .release-please-manifest.json ] || echo "**また ~/.claude/skills/create-pr/simple-title-guide.md も読み込むこと。** このリポジトリは release-please を使用していないため、シンプルなタイトル形式を使用する。"`

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

!`claude-skill-check is-public && cat ~/.claude/skills/create-pr/frontmatter-public.md || cat ~/.claude/skills/create-pr/frontmatter-private.md`

注意: Markdown のコードブロックにバッククォートを含める場合、シェルのクォートの種類によってエスケープが必要。

```bash
# double quote のときは \` でエスケープ
echo "use \`gh\` command"

# single quote のときは escape 不要
echo 'use `gh` command'
```

## 2. 人間に PR の説明をレビューしてもらう

`a ai pr-draft review` コマンドを実行して、ターミナルの新しいウィンドウで Neovim を開き、ユーザーに直接編集してもらう。

```bash
a ai pr-draft review
```

**重要:** このコマンドは非同期で実行されるため、コマンドが即座に完了してもユーザーはまだ編集中である。ユーザーがレビューを完了して明示的に指示するまで、次のステップには進まないこと。

## 3. ユーザーの指示に応じた対応

ユーザーからの指示があったら、draft ファイルを読み込んで状態を確認し、以下のように対応する。

### 修正指示の場合（「fix」「修正」など）

内容の修正のみを行う。**翻訳は行わない。**
修正後は再度 `a ai pr-draft review` を実行し、次の指示を待つ。

!`claude-skill-check is-public && cat ~/.claude/skills/create-pr/workflow-public.md || cat ~/.claude/skills/create-pr/workflow-private.md`

## 4. `a ai pr-draft submit` で PR を作成

```bash
a ai pr-draft submit [--base main]
```

frontmatter の `title` が PR タイトルとして、body 部分が PR 本文として使用される。

**注意:** submit は以下の条件をすべて満たす場合のみ成功する:

- `.lock` ファイルがない（レビュー完了）
- `.approve` ファイルがある（`steps.submit: true` でエディタを終了した）
- ファイルのハッシュが `.approve` と一致する（承認後に改ざんされていない）
  !`claude-skill-check is-public && echo "- title と body に日本語が含まれていない" || true`

## 5. CI 実行を監視

`gh pr checks --watch` コマンドを使用して CI チェックを監視します。
CI が成功したら次のステップに進みます。失敗した場合は、問題を調査・修正して再度プッシュしてください。

!`claude-skill-check is-owner fohte && cat ~/.claude/skills/create-pr/gemini-review.md || true`
