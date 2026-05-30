---
name: wiki-local
description: Read and write knowledge notes in the local Obsidian vault. Use this skill when you need to look up project context (infra config, design decisions, etc.) or save knowledge that isn't documented anywhere.
---

# Wiki Local

Obsidian vault をローカルの wiki として使い、知識の参照・蓄積を行うスキル。

## vault

- パス: !`runok exec -- obsidian vault=obsidian-v2 vault info=path`
- 全 `obsidian` コマンドで、サブコマンドの前に `vault=obsidian-v2` をつけること
- ノートの操作手順やルールは vault の CLAUDE.md を読んで従うこと

## 絶対ルール (vault CLAUDE.md を読まずに動くときの fallback)

- 新規ノートの配置先は `notes/inbox` (vault ルート直下の `inbox/` ではない)。`obsidian create` の `path=` には必ず `notes/` プレフィックスを付ける
- ノート本文の先頭に H1 見出し (ノートタイトル) を書かない。Obsidian はファイル名をタイトルとして表示するため、本文中のタイトル見出しは冗長になる。見出しは H1 を飛ばして H2 (`##`) から始める

## ノートを書くとき

新規ノートの作成や既存ノートへの大幅な追記では、いきなり全文を書かない。

- まずアウトライン (見出し構成と各セクションの結論を 1 行ずつ) を書いてユーザーに提示し、合意を得てから全文を書く。長い会話や資料の要約は特に、全文を一気に書くと構成が破綻しやすい
- アウトラインの段階で、扱う情報の取捨選択・章立て・章の並び順をユーザーと確定させる
- 太字 (`**...**`) を多用しない。強調は構造で表現する
- 各セクションは結論ファーストにする。見出し直後に結論を 1 文で書くか、結論そのものを要約見出しにする
- 各記述は「読み手がそのノートに必要な事実か」で取捨する。背景・経緯・選択肢の検討過程など本筋でない情報は削るか `<details>` に隔離する
