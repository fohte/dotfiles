{{- $task := ds "task" -}}
{{- $investigated := index $task "investigated" -}}
{{- $links := index $task "links" -}}
{{- $additionalContext := index $task "additionalContext" -}}

## 背景

### 目的・モチベーション

{{ strings.TrimSpace $task.purpose }}
{{- if $investigated }}

### 調査済みの内容

{{ strings.TrimSpace $investigated }}
{{- end }}
{{- if $links }}

### 参考リンク

{{- range $links }}

- {{ . }}
    {{- end }}
    {{- end }}
    {{- if $additionalContext }}

## 現状

{{ strings.TrimSpace $additionalContext }}
{{- end }}

## ゴール

{{ strings.TrimSpace $task.goal }}
{{ if eq (getenv "DELEGATE_DIRECT_COMMIT" "false") "true" }}
`commit` skill で commit し、push するところまで完了させること。PR は作成しない。

push まで終えたら委任元に完了を報告すること。
PR が残らないので、報告しない限り委任が終わったことが伝わらない。
報告には、どの委任か (委任元は複数の委任を並行させている)、push したコミット、ゴールに届かなかったものがあればその残りを含める。
{{- else }}
`commit` skill で commit し、`create-pr` skill で PR を作成するところまで完了させること。

{{- if eq (getenv "DELEGATE_VIBE" "false") "true" }}
## Vibe coding mode

この委任は vibe coding モードである。`create-pr` skill を使う前に `a agent vibe status` を実行し、終了コードが 0 の場合だけ以下の手順を適用する。コマンドが見つからない場合を含め、終了コードが 0 以外なら通常の委任として扱う。

vibe の場合も `commit` skill の self-review と commit / push の手順は続ける。`create-pr` skill の Step 0 では push だけを行い、crit 承認は待たない。Step 1 (manual flow では Step 2 も) から Step 7 までは `create-pr` skill の vibe 手順に従い、draft ready 通知後は委任元の「draft にコメントを書いた」「コードを直して」「承認」の返答に応じる。明示的な「承認」を受けるまで submit しない。

default branch へ直接 push する運用のリポジトリ (`is_master_push_repo` が true) でも、この委任では今のブランチで作業して PR を作り、default branch へは push しない。
{{- else }}
PR の作成・完了は委任元に `notify` しない。
merge 後に worktree が片付けられると armyknife が委任元に自動で通知する。
{{- end }}
{{- end }}

## 委任元への連絡

{{- if and (eq (getenv "DELEGATE_DIRECT_COMMIT" "false") "false") (eq (getenv "DELEGATE_VIBE" "false") "true") }}
これらの連絡ルールは `a agent vibe status` が exit 0 の場合に限り適用する。0 以外なら通常の連絡ルールに戻り、前提誤り以外は `notify` しない。draft ready と PR ready の報告以外に、進捗、質問、待ち状態を連絡せず、ターンを終える際に成果物、停止理由、待っているものをユーザーに報告する。

委任元に `notify` してよいのは、draft ready の報告、CI green 後の PR ready 報告、この指示の前提が誤っていると判明したときに限る。draft ready の返答として「draft にコメントを書いた」「コードを直して」「承認」を待つ。進捗報告や質問は送らない。
`notify` を送ったらターンを終えて待つ。返答は新しいターンとして届く。`sleep` ツールやコマンドでターン内に留まって待つと session が running のままになり、merge 後に `a agent close` で閉じられない。

draft ready、PR ready、および前提誤りを報告するときは、委任元の session_id を `a agent peer parent | jq -r '.[0].session_id // empty'` で取り、`a agent peer notify --message <MESSAGE> <SESSION_ID>` で送る。
session_id が空、または `notify` が `ended` エラーで失敗した場合は委任元が失われているので、宛先を推測せずユーザーに報告する。

委任元の返答に対応し、コメント反映後は draft ready を再送する。コード修正後は draft を作り直して draft ready を送る。承認後は submit し、CI green になってから PR ready を送る。
{{- else }}
委任元に連絡してよいのは、この指示の前提が誤っていると判明したときと、上で報告するよう指示したときに限る。
進捗報告、質問、作業を続けられずに止まることの報告は送らない。
委任元の管理下にあるもの (別リポジトリの修正、パッケージの publish、先行 PR の merge など) を待って止まった場合も連絡しない。
解消したら委任元から通知が来る。
crit でのレビューや PR body の確認など、人間の操作を待っていることも、その待ちが解けたことも連絡しない。

これらの制限は委任元への `notify` にだけかかる。
このセッションの応答はユーザーが直接読むので、ターンを終えるときは、作ったもの (PR やコミット)、止まった理由、待っているものを応答に書く。

連絡するときは、委任元の session_id を `a agent peer parent | jq -r '.[0].session_id // empty'` で取り、`a agent peer notify --message <MESSAGE> <SESSION_ID>` で送る。
session_id が空、または `notify` が `ended` エラーで失敗した場合は委任元が失われているので、宛先を推測せずユーザーに報告する。
{{- end }}
