---
name: development
description: Development (実装フルフローモード). Use this skill when implementing features, making changes, or refactoring code. Covers the full cycle from investigation through design, implementation, and commit.
---

# Development (実装フルフローモード)

機能追加、変更、リファクタリングなど、コード変更を伴うタスクを一貫して行うスキル。

## フロー概要

1. 要件理解・コード調査
2. 設計
3. 実装を delegate

**原則: main/master ブランチで直接実装しない。** 調査と設計はこのセッションで行い、実装は `/delegate-claude` で別 worktree に委任する。

**直接実装する例外**:

- dotfiles のように main で直接作業するリポジトリ
- `/delegate-claude` によって worktree 内で動作している場合 (既に delegate 済み)

---

## Step 1: 要件理解・コード調査

タスクの要件を理解し、実装に必要なコンテキストを収集する。

- 関連する既存コードの構造を把握する
- 類似実装があれば参考にする (Grep/Glob で検索)
- ディレクトリ構造と命名規則を確認する
- CLAUDE.md やプロジェクト固有の制約を確認する

複数の観点で調査が必要な場合は、Task ツールで並列にサブエージェントを起動する。

## Step 2: 設計

`/design` スキルを呼び出し、設計案を検討する。

**スキップ条件**: 以下の場合はこのステップをスキップしてよい:

- 変更が 1-2 ファイルで済む小さなタスク
- 設計判断が不要な単純な修正 (typo 修正、設定値変更など)
- ユーザーが具体的な実装方法を指定している場合

## Step 3: 実装

### 通常 (デフォルト)

**Step 1-2 をこのセッションで完了させた上で**、`/delegate-claude` スキルで実装を委任する。

プロンプトには以下を含めること:

- **背景**: タスクの目的と経緯
- **現状**: 調査・設計の結果
- **ゴール**: 具体的な実装内容と設計方針

### 例外: main で直接作業可能なリポジトリ

このセッション内で実装を行い、完了後に `/commit` スキルでコミットする。

- テストが存在するプロジェクトでは、`/test-philosophy` スキルの方針に従ってテストも書く
- 実装中に設計の問題に気づいた場合は、ユーザーに相談する
