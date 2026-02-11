{{- $v := ds "vars" -}}
{{- $public := eq $v.repo.visibility "PUBLIC" -}}
{{- $owner_fohte := eq $v.repo.owner.login "fohte" -}}
{{- $repo_specs := eq $v.repo.name "specs" -}}
{{- $release_please := eq (conv.ToString $v.has_release_please) "true" -}}

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
{{- if $repo_specs }}

## 1. PR を作成する

**まず ~/.claude/skills/create-pr/writing-guide.md を読み込むこと。** タイトルと description の書き方ルールが定義されている。
{{- if $release_please }}

**また ~/.claude/skills/create-pr/release-please-guide.md も読み込むこと。** このリポジトリは release-please を使用しているため、Conventional Commits 形式を使用する必要がある。
{{- else }}

**また ~/.claude/skills/create-pr/simple-title-guide.md も読み込むこと。** このリポジトリは release-please を使用していないため、シンプルなタイトル形式を使用する。
{{- end }}

**重要:** このドラフトは **常に日本語で書くこと**。

`gh pr create` コマンドを使用して PR を直接作成する。body は雑でよい。完璧さより速度を優先する。

**body のルール:**

- Why/What を各 1-2 行で簡潔に書く
- 日本語で書く
- コード要素は `` ` `` で囲む

```bash
gh pr create --title "タイトル" --body "$(cat <<'EOF'
## Why

- ...

## What

- ...
EOF
)"
```

PR URL を表示したら、次のステップに進む。
{{- else }}

## 1. PR body のドラフトファイルを作成する

**まず ~/.claude/skills/create-pr/writing-guide.md を読み込むこと。** タイトルと description の書き方ルールが定義されている。
{{- if $public }}

**また ~/.claude/skills/create-pr/public-repo-guide.md も読み込むこと。** このリポジトリは public であるため、英語ライティングガイドラインと翻訳ルールに従う必要がある。
{{- end }}
{{- if $release_please }}

**また ~/.claude/skills/create-pr/release-please-guide.md も読み込むこと。** このリポジトリは release-please を使用しているため、Conventional Commits 形式を使用する必要がある。
{{- else }}

**また ~/.claude/skills/create-pr/simple-title-guide.md も読み込むこと。** このリポジトリは release-please を使用していないため、シンプルなタイトル形式を使用する。
{{- end }}

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
{{- if $public }}

```yaml
---
title: 'PRタイトル'
steps:
    ready-for-translation: false
    submit: false
---
```

- `title`: PR のタイトル（submit 時に使用される）
- `steps.ready-for-translation`: ドラフト承認フラグ。true になったら翻訳を実行する。public repo では翻訳は**必須**であり、submit 時に日本語が含まれているとエラーになる
- `steps.submit`: true にするとエディタ終了時にファイルのハッシュが保存される。submit 時にハッシュが一致しないと失敗する（改ざん防止）
  {{- else }}

```yaml
---
title: 'PRタイトル'
steps:
    submit: false
---
```

- `title`: PR のタイトル（submit 時に使用される）
- `steps.submit`: true にするとエディタ終了時にファイルのハッシュが保存される。submit 時にハッシュが一致しないと失敗する（改ざん防止）
  {{- end }}

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
{{- if $public }}

### ドラフト承認後の翻訳（`steps.ready-for-translation: true` かつ日本語含む）

**重要:** public repo では翻訳は**必須**である。`steps.ready-for-translation` は「翻訳するかしないか」の選択ではなく、「ドラフトの内容が承認され、翻訳の準備ができたか」を示すフラグ。

ユーザーがドラフトの内容を承認し、`steps.ready-for-translation: true` に変更した場合:

1. title と body を英語に翻訳する
2. `steps.submit: false` に変更する（翻訳によりハッシュが無効になるため）
3. ファイルを上書き保存する
4. 再度 `a ai pr-draft review` を実行して、ユーザーに翻訳内容を確認してもらう
5. ユーザーがレビューを完了して明示的に指示するまで待機する

翻訳時の注意事項は ~/.claude/skills/create-pr/public-repo-guide.md の「翻訳時の注意」セクションに従うこと。

**注意:** すでに英語に翻訳済み（日本語が含まれていない）の場合は、再翻訳しない。
{{- else }}

### Submit への進め方

翻訳は不要。ユーザーが `steps.submit: true` にしたら submit に進む。
{{- end }}

## 4. `a ai pr-draft submit` で PR を作成

```bash
a ai pr-draft submit [--base main]
```

frontmatter の `title` が PR タイトルとして、body 部分が PR 本文として使用される。

**注意:** submit はユーザーがレビューを完了し承認済みの場合のみ成功する。失敗した場合はエラーメッセージをそのままユーザーに伝えること。
{{- if $public }}

- title と body に日本語が含まれていない
  {{- end }}
  {{- end }}

## {{ if $repo_specs }}2{{ else }}5{{ end }}. CI 実行を監視

`gh pr checks --watch` コマンドを使用して CI チェックを監視します。
CI が成功したら次のステップに進みます。失敗した場合は、問題を調査・修正して再度プッシュしてください。
{{- if $owner_fohte }}

## {{ if $repo_specs }}3{{ else }}6{{ end }}. Gemini Code Assist レビューを待機

CI が成功したら、`a ai review wait` コマンドを使用して Gemini Code Assist のレビュー完了を待機します（初回レビューは PR 作成時に自動でリクエストされる）。

```bash
a ai review wait
```

レビューが完了したら、`check-pr-review` skill を使用してレビュー内容を確認し、指摘事項があれば対応してください。
{{- end }}
