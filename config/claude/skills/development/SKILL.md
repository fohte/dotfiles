---
name: development
description: Development (実装フルフローモード). Use this skill when implementing features, making changes, or refactoring code. Covers the full cycle from investigation through design, implementation, and commit.
---

# Development (実装フルフローモード)

機能追加、変更、リファクタリングなど、コード変更を伴うタスクを一貫して行うスキル。

## フロー概要

1. 要件理解・コード調査
2. 設計
3. 実装

**原則: 調査・設計・実装を同じセッションで行う。** 別セッションに委任すると、委任先が文脈を読み直す分と、そのレビューの分だけトークンが増えるため。ただし、main/master ブランチのチェックアウトでは実装しない (Step 3 参照)。

---

## Step 1: 要件理解・コード調査

タスクの要件を理解し、実装に必要なコンテキストを収集する。

- 関連する既存コードの構造を把握する
- 類似実装があれば参考にする (codebase-memory の `search_graph` で検索、見つからなければ Grep/Glob)
- ディレクトリ構造と命名規則を確認する
- CLAUDE.md やプロジェクト固有の制約を確認する

複数の観点で調査が必要な場合は、並列にサブエージェントを起動する (Claude Code: Task ツール / Codex: `spawn_agent` + `wait_agent`)。

## Step 2: 設計

`/design-flow` (Codex: `$design-flow`) スキルを呼び出し、設計案を検討する。

**スキップ条件**: 以下の場合はこのステップをスキップしてよい:

- 変更が 1-2 ファイルで済む小さなタスク
- 設計判断が不要な単純な修正 (typo 修正、設定値変更など)
- ユーザーが具体的な実装方法を指定している場合

ゴールが明確なら、仕様の詳細は自分で決めて進める。ユーザーに聞くのは、`project-manager` skill の `assets/handoff-common.md` の手順 3 に挙げた基準に当たる論点だけにする。

## Step 3: 実装

今いる場所で分岐する。

| 場所                                                          | 実装の仕方                                                                                    |
| ------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `repo.direct_commit` が `true` のリポジトリ                   | このセッションで実装し、`/commit` (Codex: `$commit`) スキルでコミットする                     |
| `.worktrees/<name>` か `.claude/worktrees/<name>` の worktree | このセッションで実装し、`/commit` でコミット、`/create-pr` (Codex: `$create-pr`) で PR を作る |
| (それ以外) default branch のチェックアウト                    | 下記の手順で自分が worktree に入り、上の行に従う。`delegate` は使わない                       |

Claude Code では `EnterWorktree` に `name` (delegate skill のブランチ名の規則に従う) を渡す。WorktreeCreate hook が `.claude/worktrees/<name>` に `fohte/<name>` ブランチで作る。tq タスクがあれば、入った後に `git config branch.fohte/<name>.x-tq-task-id <task-id>` を記録する (PR の葉項目があれば `x-tq-checklist-item-id` も)。create-pr skill が PR を tq に紐付けるのに使う。2 本目以降の PR は `project-manager` skill の `assets/handoff-common.md` の手順 5 でブランチを作る。worktree の中で Claude Code の隔離チェックにコマンドを拒否されたら、ユーザーに実行を頼まず、`ExitWorktree` (action: `keep`) で抜けて実行し、同じ `name` の `EnterWorktree` で入り直す。

`EnterWorktree` が無い Codex でも、新しいセッションは起動せず、このセッションで実装する。`jq -nc --arg name <name> --arg cwd "$PWD" '{name:$name,cwd:$cwd}' | ~/.claude/hooks/worktree-create` で同じ worktree を作り、出力の最終行のパスを以降のコマンドの `workdir` とファイル編集の場所にする。tq の記録は Claude Code と同じ。

- テストが存在するプロジェクトでは、`/test-philosophy` (Codex: `$test-philosophy`) スキルの方針に従ってテストも書く
- 実装中に設計の問題に気づいた場合も、Step 2 と同じ基準で、自分で決めるかユーザーに相談するかを分ける
