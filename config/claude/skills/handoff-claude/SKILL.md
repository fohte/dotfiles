---
name: handoff-claude
description: Write a Markdown handoff file that lets the user start a fresh Claude Code session and pick up the current task — for resetting a session with accumulated context (like a manual auto-compact), switching to a different or more capable model, or getting an independent second opinion from a new session on the same problem. Also use this inside a session that itself was started from a handoff, when the user wants to write up a report to carry back to the session that started it. Trigger ONLY on an explicit, deliberate request for this handoff/report — the user runs `/handoff-claude`, or clearly asks to hand off the session, switch models and continue, or bring results back to the original session. Do not trigger just because context is getting long or a model name comes up in passing conversation — only act when the user explicitly asks for the handoff itself.
---

# 別の Claude Code セッションへ作業を引き継ぐ

現在のセッションのコンテキストを Markdown ファイルに書き出し、新しいセッションが引き継げるようにする。新しいセッションを実際に起動するのはユーザー自身であり、このスキルの仕事はファイルを用意して案内するところまで。

## 最優先ルール

- **ユーザーが明示的に依頼した時だけ動く**: 「コンテキストが溜まってきたな」といった独り言や、モデル名が話題に出ただけでは発動しない。発動した以上、引き継ぎ資料の作成自体は迷わず実行する
- **新しいセッションを自分で起動しない**: `tmux` や `a wm new` などで新しい Claude Code プロセスを起動する処理は行わない。ファイルを書き出し、起動コマンドを案内するところまでが仕事

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
- **セカンドオピニオン / 別の観点で調べ直したい**: 結論をいきなり渡すと新しいセッションがそれに引っ張られ、独立した再検証にならない。「まず自分で調査してから、末尾にある元セッションの結論と照合する」という指示を添え、結論は文書の最後に置く

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

### 案内する内容

ファイルパスと、新しいセッションを起動するコマンド例を伝える。ユーザーがモデルを指定していればそれを反映する。

```bash
claude "$(cat "$dir/handoff.md")"
# モデルを切り替える場合
claude --model <model-id> "$(cat "$dir/handoff.md")"
```

元のセッションを `/clear` するかそのまま残すかはユーザーの判断に委ねる。指示がなければ両方の選択肢があることだけ伝え、決めつけない。

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

### 案内する内容

ファイルパスを伝え、元のセッションに貼り付けて渡すようユーザーに依頼する。別プロセスの Claude Code セッション間で直接メッセージを送る手段はないため、この受け渡しは人間が仲介する。
