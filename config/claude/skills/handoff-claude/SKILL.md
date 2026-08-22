---
name: handoff-claude
description: Write a Markdown handoff file and start a fresh Claude Code session with it (`a cc new`) so that session picks up the current task — for resetting a session with accumulated context (like a manual auto-compact), switching to a different or more capable model, or getting an independent second opinion from a new session on the same problem. Also use this inside a session that itself was started from a handoff, when the user wants to write up a report to carry back to the session that started it. Trigger ONLY on an explicit, deliberate request for this handoff/report — the user runs `/handoff-claude`, or clearly asks to hand off the session, switch models and continue, or bring results back to the original session. Do not trigger just because context is getting long or a model name comes up in passing conversation — only act when the user explicitly asks for the handoff itself.
---

# 別の Claude Code セッションへ作業を引き継ぐ

現在のセッションのコンテキストを Markdown ファイルに書き出し、`a cc new` で新しいセッションを起動して引き継ぐ。

## 最優先ルール

- **ユーザーが明示的に依頼した時だけ動く**: 「コンテキストが溜まってきたな」といった独り言や、モデル名が話題に出ただけでは発動しない。発動した以上、引き継ぎ資料の作成自体は迷わず実行する
- **起動は `a cc new` を使う**: `tmux` や `claude` を直接叩いて起動しない。`a cc new` 経由でないと新セッションが `a cc` の管理下に入らず、親子関係が張られないため持ち帰りの経路 (`a cc peer parent` + SendMessage) が使えなくなる

## モードの判定

ユーザーの言い方から「送り出し」か「持ち帰り」かを判断する。判断がつかない場合は聞く。

- **送り出し**: 今のセッションの作業を新しいセッションに渡したい (コンテキストリセット / モデル切り替え / セカンドオピニオン)
- **持ち帰り**: 今のセッション (= 引き継ぎ先) での作業結果を、引き継ぎ元のセッションに戻したい

## 共通: ファイルの置き場所

`mktemp -d` で一意なディレクトリを作り、その下に Markdown を書く。固定パスは過去の引き継ぎファイルと衝突するため使わない。

```bash
dir=$(mktemp -d -t handoff-claude.XXXXXX)
```

書き終えたらファイルパスをユーザーに提示する。

## 送り出しモード

### 引き継ぐ理由を確認する

ユーザーの発言から理由が分かればそれに従う。分からなければ聞く。理由によって書き方が変わるため省略しない。

- **コンテキストリセット / モデル切り替え**: これまでの進捗をそのまま渡せばよい
- **セカンドオピニオン / 別の観点で調べ直したい**: 結論をいきなり渡すと新しいセッションがそれに引っ張られ、独立した再検証にならない。「まず自分で調査してから、末尾にある元セッションの結論と照合する」という指示を添え、結論は文書の最後に置く。結果を元セッションに返してほしい場合は、「次にやってほしいこと」に持ち帰りモードで報告する旨を明記する

### 引き継ぎファイルの構成

`$dir/handoff.md` に以下を書く。セカンドオピニオン目的の場合は「これまでの進捗」を末尾に回し、冒頭にその旨を明記する。

```markdown
# 引き継ぎ: <タスクの短い要約>

## 引き継ぐ理由

<コンテキストリセット / モデル切り替え / セカンドオピニオン、いずれか + 具体的な事情>

## 背景と目的

<なぜこのタスクをやっているか。何を実現したいか>

## これまでの進捗

<分かっていること、決めたこととその理由、試したこと>

## 次にやってほしいこと

<新しいセッションのゴール>

## 参考情報

<関連ファイルパス、URL、既に実行したコマンドなど>
```

### 新しいセッションを起動する

`--worktree` は付けない。引き継ぎは同じ作業ディレクトリでの続きであり、worktree もブランチも作る必要がないため。

```bash
a cc new --prompt "$(cat "$dir/handoff.md")" --label "<タスクの短い要約>"
# モデルを切り替える場合
a cc new --prompt "$(cat "$dir/handoff.md")" --label "..." --model <model-id>
```

`--agent` は使わない。委任用の context が被さり、「完了報告を送るな」という指示まで新セッションに入ってしまうため。引き継ぎ元へ報告してほしい場合は、後述のとおり handoff.md 本文に書く。

Claude Code から起動した新セッションは、フォーカスを奪わないよう、同じ tmux window を分割した隣の pane にバックグラウンドで開く。ユーザーには起動した旨とファイルパスを伝え、別 window に分けたい場合は `break-pane` で切り出せる旨を添える。元のセッションを `/clear` するかそのまま残すかはユーザーの判断に委ねる。

## 持ち帰りモード

### レポートファイルの構成

`$dir/report.md` に以下を書く。

```markdown
# 持ち帰りレポート: <タスクの短い要約>

## 引き継がれた内容

<このセッションが何を頼まれていたか>

## 調査と作業の結果

<分かったこと、やったこと>

## 結論と推奨

<結論。次のアクションがあれば書く>

## 元セッションへの申し送り

<元セッションが知っておくべきこと、未解決の論点>
```

### 元セッションに渡す

`a cc new` で起動されたセッションなら、元セッションへ直接 SendMessage できる。

```bash
a cc peer parent | jq -r '.[0].name // empty'
```

得られた名前を `SendMessage` の `to` に渡し、本文には要約とレポートのファイルパスを書く (全文は貼らない)。名前が空なら `a cc peer wake $(a cc peer parent | jq -r '.[0].session_id')` を実行し、出力された名前を `to` に使う。

`a cc peer parent` 自体が空の場合 (`a cc new` 以外で起動されたセッション) と、`wake` がエラーになる場合 (元セッションが `/exit` 済みで resume できない) は、ファイルパスを伝えて元セッションへの受け渡しをユーザーに依頼する。
