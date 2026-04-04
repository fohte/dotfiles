{{- $v := ds "vars" -}}
{{- $lang_override := eq $v.repo_language "ja" -}}
{{- $public := and (eq $v.repo.visibility "PUBLIC") (not $lang_override) -}}
{{- $owner_fohte := eq $v.repo.owner.login "fohte" -}}
{{- $repo_specs := eq $v.repo.name "specs" -}}
{{- $release_please := eq (conv.ToString $v.has_release_please) "true" -}}

# Create PR

変更を push した後、以下の手順で PR を作成する。

**重要:** diff の確認には必ず `origin/master` と比較すること (`git diff origin/master...HEAD`)。ローカルの `master` は古い可能性がある。

ワークフローの詳細 (Frontmatter、エスケープ、exit code 等) は `~/.claude/skills/create-pr/rules/pr-draft-workflow.md` を参照。

## 1. PR body のドラフトを作成する

**まず ~/.claude/skills/create-pr/writing-guide.md を読み込むこと。** ルール一覧に従い、違反しそうなルールは `rules/<ルール名>.md` で詳細を確認。
{{- if $release_please }}
**また `~/.claude/skills/create-pr/rules/title-conventional-commits.md` も読み込むこと。** このリポジトリは release-please を使用しているため、Conventional Commits 形式を使用する。
{{- else }}
**また `~/.claude/skills/create-pr/rules/title-simple-format.md` も読み込むこと。** このリポジトリは release-please を使用していないため、シンプルなタイトル形式を使用する。
{{- end }}

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

```bash
echo "## Why

- <修正系: 症状/影響のみ / 新規追加: 目的>

## What

- <変更の効果を簡潔に>
  - <技術的原因があれば子要素として補足>" | a ai pr-draft new --title "PRタイトル"
```

ドラフトは `/tmp/pr-body-draft/<owner>/<repo>/<branch>.md` に作成される。以降のコマンドではパス指定不要。

## 2. レビュー

`a ai pr-draft review` を **バックグラウンドで** (`run_in_background: true`) 実行。完了を待ち、exit code で判断 (詳細は `rules/pr-draft-workflow.md`)。

## 3. ユーザーの指示に応じた対応

draft ファイルを読み込んで状態を確認し、以下のように対応する。

### 修正指示の場合

**~/.claude/skills/create-pr/writing-guide.md を再読すること。** 修正対象のルールに該当する `rules/<ルール名>.md` も読んで詳細を確認。

修正のみ行い、**翻訳は行わない**。修正後は再度 `a ai pr-draft review` をバックグラウンドで実行し、完了を待つ。
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
{{- if $owner_fohte }}

## {{ if $repo_specs }}3{{ else }}6{{ end }}. Gemini Code Assist レビューを待機

`a ai review wait` でレビュー完了を待機し、`check-pr-review` skill で指摘事項に対応。
{{- end }}
