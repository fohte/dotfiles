{{- $v := ds "vars" -}}
{{- $lang_override := eq $v.repo_language "ja" -}}
{{- $public := and (eq $v.repo.visibility "PUBLIC") (not $lang_override) -}}
{{- $owner_fohte := eq $v.repo.owner.login "fohte" -}}
{{- $repo_specs := eq $v.repo.name "specs" -}}
{{- $release_please := eq (conv.ToString $v.has_release_please) "true" -}}
{{- $has_pr_template := ne (conv.ToString $v.pr_template) "" -}}

# Create PR

変更を push した後、以下の手順で PR を作成する。

**重要:** diff の確認には必ず `origin/master` と比較すること (`git diff origin/master...HEAD`)。ローカルの `master` は古い可能性がある。

ワークフローの詳細 (Frontmatter、エスケープ、exit code 等) は `~/.claude/skills/create-pr/rules/pr-draft-workflow.md` を参照。

## 1. PR body のドラフトを作成する

**ドラフトを書き始める前に、以下のファイルを必ず全て読むこと。** 「違反しそうなものだけ」「概要だけ」で済ませてはならない。概要表からは、どのルールが今回の変更に効いてくるかを事前に判断することはできない (自分で違反に気づけないからルール集が存在する)。ルールを読まずに書いたドラフトは、ユーザーから「ながすぎ」「内訳が多い」等の差し戻しを受けてから読み直すことになり、ユーザーに同じ指摘を繰り返し書かせる結果になる。

必読ファイル:

- `~/.claude/skills/create-pr/writing-guide.md` (概要表)
- writing-guide.md の「Why セクション」「What セクション」の表に列挙されている `rules/<ルール名>.md` を**全て**
  {{- if $release_please }}
- `~/.claude/skills/create-pr/rules/title-conventional-commits.md` (このリポジトリは release-please を使用しているため、Conventional Commits 形式を使用する)
  {{- else }}
- `~/.claude/skills/create-pr/rules/title-simple-format.md` (このリポジトリは release-please を使用していないため、シンプルなタイトル形式を使用する)
  {{- end }}

**効率化のため、これらは並列で Read すること。** writing-guide.md を読んでから個別ルールを読むのではなく、writing-guide.md に列挙されているルール名は既知なので、最初から全ファイルを一括で並列読み込みする。

ドラフトは **常に日本語で書くこと**。
{{- if $repo_specs }}

`gh pr create` で PR を直接作成する。body は雑でよい。完璧さより速度を優先。

```bash
gh pr create --title "タイトル" --body "$(cat <<'EOF'
## Why

- ...

## What

- ...
EOF
)"
```

{{- else }}
{{- if $has_pr_template }}

**以下の PR template のセクション構造に従うこと。**

```markdown
{{ $v.pr_template }}
```

ルール:

- 上記 template の見出し構造をそのまま踏襲し、各セクションを埋める
- コメント指示 (`<!-- ... -->`) はドラフトから削除する
- writing-guide.md の **基本ルールとセクション内部の書き方** (コードはバッククォート、根拠には引用+出典、What not How、具体例の提示など) は template の全セクションに適用する。Why/What の見出し固定や「Why/What のみ記述」といったセクション構造に関するルールは template の構造に置き換わる

```bash
cat <<'EOF' | a ai pr-draft new --title "PRタイトル"
<template の構造に従ったドラフト本文>
EOF
```

{{- else }}

```bash
echo "## Why

- <修正系: 症状/影響のみ / 新規追加: 目的>

## What

- <変更の効果を簡潔に>
  - <技術的原因があれば子要素として補足>" | a ai pr-draft new --title "PRタイトル"
```

{{- end }}

ドラフトは `/tmp/pr-body-draft/<owner>/<repo>/<branch>.md` に作成される。以降のコマンドではパス指定不要。

**書き終えたら `a ai pr-draft new` 実行前にセルフチェックを必ず行うこと。** これは執筆前の事前 Read とは別の工程で、省略してはならない。

手順:

1. writing-guide.md と Why/What の表に列挙された全 `rules/<ルール名>.md` を **Read ツールで開き直す** (頭の中の要約で代替しない)
2. ドラフトの各行を、開いた各ルールの ❌/✅ パターンに照らして 1 行ずつ照合する
3. 違反があれば修正してから `a ai pr-draft new` を実行する

「ルールを読んだ = 違反していない」ではない。事前 Read したルールは執筆中に頭から抜ける。書いた後にルールファイルを開き直して照合しない限り、違反を残したまま提出し、ユーザーから差し戻しを受けて結局同じルールを全部再読することになる。

特に見逃しやすい違反:

- `what-no-implementation-breakdown`: 設定キー名・値・件数・ファイル名の内訳をサブバレットで並べてしまう
- `why-symptoms-only`: 症状に続けて技術的原因 (「〜が〜していたため」) を混入させてしまう
- `what-not-how`: 具体的な設定値や SDK 名を What に書いてしまう
- 「〇〇は残す」という現状維持の言及 (レビュアーは diff で見えないもの = 言及不要)

## 2. レビュー

`a ai pr-draft review` を **バックグラウンドで** (`run_in_background: true`) 実行。完了を待ち、exit code で判断 (詳細は `rules/pr-draft-workflow.md`)。

**polling 禁止**: バックグラウンドで起動した後は `<task-notification>` の完了通知が届くまで何もしないこと。`while` ループ・`sleep` ループ・出力ファイルの繰り返し読み取りで進捗を確認してはならない。通知が届いてから出力ファイルを 1 回だけ読む。これは `a ai pr-draft review` だけでなく、`a ai review wait` や `gh pr checks --watch` など本スキル内のすべてのバックグラウンドコマンドに共通するルール。

## 3. ユーザーの指示に応じた対応

`a ai pr-draft review` が exit code 0 以外で完了したら、**まず draft ファイルを最初から最後まで全行読むこと**。理由:

- ユーザーはエディタで任意の位置に自由形式のコメント行 (例: 「ここながすぎ」「この例まちがってる」) を書き足してから閉じることがある
- `steps.ready-for-translation` や `steps.submit` が変わっていなくても、本文中にユーザーの差し戻しコメントが残っている場合がある
- frontmatter の `steps` だけ見て「変更なし」と判断して次の review を再起動すると、ユーザーは同じ指摘を繰り返し書かされることになる

次に frontmatter と本文の両方を踏まえて、以下のいずれかに振り分ける。

### 修正指示の場合

**~/.claude/skills/create-pr/writing-guide.md と、そこに列挙されている Why/What の全 `rules/<ルール名>.md` を再読すること。** 差し戻しは「自分が事前に違反に気づけなかったルール」に起因している可能性が高く、指摘対象と思い込んだルールだけ読むと別のルール違反を見逃す。Step 1 と同様、最初から全ファイルを並列読み込みすること。

修正のみ行い、**翻訳は行わない**。ユーザーが本文に書き込んだコメント行は、対応後に削除してから保存する。修正後は再度 `a ai pr-draft review` をバックグラウンドで実行し、完了を待つ。
{{- if $public }}

### ドラフト承認後の翻訳 (`steps.ready-for-translation: true` かつ日本語含む)

public repo では翻訳は**必須**。`steps.ready-for-translation: true` になったら:

1. `rules/translation.md` と `rules/english-writing.md` を読む
2. title と body を英語に翻訳し、`steps.submit: false` に変更して保存
3. `a ai pr-draft review` をバックグラウンドで実行し、完了を待つ

すでに英語に翻訳済みの場合は再翻訳しない。
{{- else }}

### Submit への進め方

翻訳は不要。ユーザーが `steps.submit: true` にしたら submit に進む。
{{- end }}

## 4. Submit

```bash
a ai pr-draft submit [--base main]
```

既存 PR がある場合は title と body を更新する。submit はユーザーが承認済みの場合のみ成功する。
{{- if $public }}
title と body に日本語が含まれていないこと。
{{- end }}
{{- end }}

## {{ if $repo_specs }}2{{ else }}5{{ end }}. CI 実行を監視

`gh pr checks --watch` で CI を監視。失敗した場合は調査・修正して再 push。
{{ if $owner_fohte }}

## {{ if $repo_specs }}3{{ else }}6{{ end }}. Gemini Code Assist レビューを待機

`a ai review wait` でレビュー完了を待機する。
{{ end }}

## {{ if $repo_specs }}{{ if $owner_fohte }}4{{ else }}3{{ end }}{{ else }}{{ if $owner_fohte }}7{{ else }}6{{ end }}{{ end }}. レビューコメントを確認して対応する

**CI や bot のチェックが `pass` でも、レビューコメントが付いていることがある。CI pass = レビュー指摘なし ではない。** submit 後は必ず `/check-pr-review` skill を実行し、CodeRabbit / Devin / Gemini Code Assist 等の自動レビュー、および人間のレビュアーからのコメントを確認して対応すること。

`check-pr-review` skill の中断・省略は禁止。「指摘がなさそうだから」「CI が通ったから」といった判断で skip してはならない。
