---
name: handoff
description: Write a Markdown handoff file and start a fresh agent session with it (`handoff/scripts/launch`) so that session picks up the current task — for resetting a session with accumulated context (like a manual auto-compact), switching to a different or more capable model, or getting an independent second opinion from a new session on the same problem. Also use this inside a session that itself was started from a handoff, when the user wants to write up a report to carry back to the session that started it. Trigger ONLY on an explicit, deliberate request for this handoff/report — the user runs `/handoff`, or clearly asks to hand off the session, switch models and continue, or bring results back to the original session. Do not trigger just because context is getting long or a model name comes up in passing conversation — only act when the user explicitly asks for the handoff itself.
---

# 別の agent session へ作業を引き継ぐ

現在のセッションのコンテキストを Markdown ファイルに書き出し、`scripts/launch` で新しいセッションを起動して引き継ぐ。

## 最優先ルール

- **ユーザーが明示的に依頼した時だけ動く**: 「コンテキストが溜まってきたな」といった独り言や、モデル名が話題に出ただけでは発動しない。発動した以上、引き継ぎ資料の作成自体は迷わず実行する
- **起動は handoff の `scripts/launch` を使う**: `tmux` や `claude` を直接叩いて起動しない。launcher が内部で `a agent new --type handoff` を実行し、新セッションを `a agent` の管理下に置いて親子関係を作るため、持ち帰りの経路 (`a agent peer parent` + `a agent peer notify`) を使える

## モードの判定

ユーザーの言い方から「送り出し」か「持ち帰り」かを判断する。判断がつかない場合は聞く。

- **送り出し**: 今のセッションの作業を新しいセッションに渡したい (コンテキストリセット / モデル切り替え / セカンドオピニオン)
- **持ち帰り**: 今のセッション (= 引き継ぎ先) での作業結果を、引き継ぎ元のセッションに戻したい

## 共通: ファイルの置き場所

`mktemp -d` で一意なディレクトリを作り、その下に Markdown を書く。固定パスは過去の引き継ぎファイルと衝突するため使わない。

```bash
dir=$(mktemp -d "$AGENT_TMPDIR/handoff.XXXXXX")
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

handoff launcher は文書本文を prompt にし、`--type handoff` と親子関係を固定する。委任扱い、worktree、engine/model/effort の上書きは渡さない。

`--kind` には引き継ぐ workflow の表示名を渡す。設計 handoff では `design` を指定する。profile 選択は `--type handoff` が行うため、`--kind` は起動設定を変えない。

引き継ぐ作業が現在の作業ディレクトリの状態を必要とする場合は `--repo` を省略する。独立した調査のように repo root から始める場合は `--repo "$(git root -r)"` を指定する。repo を指定するときは worktree の root ではなく main repository root を渡す。

- **現在の状態が必要** → `--repo` を省略する。コンテキストリセットやモデル切り替えのように、同じブランチの作業を続ける場合はこちら
- **現在の状態が不要** → `--repo "$(git root -r)"` を指定する。セカンドオピニオンや別トピックの再調査のように、branch に依存しない場合はこちら

```bash
~/.agents/skills/handoff/scripts/launch \
  --handoff "$dir/handoff.md" --kind design --label "<タスクの短い要約>"

# branch に依存しない場合
~/.agents/skills/handoff/scripts/launch \
  --handoff "$dir/handoff.md" --repo "$(git root -r)" \
  --kind research --label "<タスクの短い要約>"
```

`a agent profile show` で選択中 profile と各 type の設定を確認し、切り替える場合は `a agent profile use <PROFILE>` を使う。launcher は `--type handoff` を固定するため、engine、model、reasoning effort は選択中 profile の `handoff` type 設定で決まる。起動時の flag による上書きは受け付けない。

引き継ぎ元へ報告してほしい場合は、後述のとおり handoff.md 本文に書く。

worktree 内から `--repo` を指定した場合、元 worktree の未コミット変更は引き継ぎ先から見えない。必要なら handoff.md の「参考情報」に元の cwd を書く。git 管理外のディレクトリでは repo を指定しない。

launcher は `--help` と `--dry-run` に対応する。`--child-launch allow` を固定し、引き継ぎ先が必要に応じて子 session を起動できるようにする。この権限は完了報告の指示を変えない。「完了報告を送るな」という文は `delegate/scripts/prompt-template.md` の通常 delegate prompt にあり、Armyknife の起動フラグが追加するものではない。

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

`a agent new` で起動されたセッションなら、元セッションへ直接 `a agent peer notify` で送れる。

```bash
a agent peer parent | jq -r '.[0].session_id // empty'
```

得られた `session_id` を使い、`a agent peer notify --message "<要約とレポートのファイルパス>" <session_id>` で送る (全文は貼らない)。元セッションが `paused` で止まっていても armyknife が内部で再開してから配送する。

`session_id` が空の場合 (`a agent new` 以外で起動されたセッション) と、`notify` が `ended` エラーで失敗する場合 (元セッションが `/exit` 済み) は、ファイルパスを伝えて元セッションへの受け渡しをユーザーに依頼する。

### 元セッション側で子セッションを閉じる

レポートを受け取ったら、元セッションで子の `session_id` を確認し、直接の子であることを検証しながら閉じる。

```bash
a agent peer children
a agent close --child <session_id>
```

`--child` は対象が呼び出し元の直接の子でなければ、セッションや pane を閉じる前に拒否する。孫セッションは対象外で、`--force` を付けてもこの検証は外れない。子が実行中・入力待ち、pending task、未送信 draft のいずれかを持つと close は拒否されるため、子が完了してから再実行する。未 merge の worktree を削除する確認が出た場合は、内容を確認して判断する。未完了の作業を破棄するときだけ `--force` を付ける。
