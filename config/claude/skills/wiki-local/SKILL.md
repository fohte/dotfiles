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
