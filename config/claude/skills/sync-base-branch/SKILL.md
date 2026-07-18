---
name: sync-base-branch
description: Merge a PR's base branch (master/main, or any other base) into the current worktree branch, resolve any merge conflicts, check whether the incoming changes require follow-up work, and push the result. Use this skill whenever the user asks to bring in, catch up with, or sync with the base branch while working on a branch/worktree — e.g. "base branch 取り込んで", "master 取り込んでコンフリクト直して", "catch up with main", "resolve conflicts with the base branch and push". Always use this skill for that pattern instead of running git merge/push manually.
---

# Sync base branch

worktree で作業中のブランチに base branch (master/main など) の更新を取り込み、conflict を解消し、追従が必要な変更がないか確認したうえで push するまでを一気に行う。

## 方針

- **merge のみを使う。rebase はしない。** rebase は force-push を要求するが、force-push は共有履歴や他者の作業を壊しうる破壊的操作であり、このスキルでは行わない。merge なら通常の push で完結する
- conflict の解消はユーザーに確認せず自律的に進める。判断根拠は最後の報告にまとめ、ユーザーが後から検証できるようにする
- 途中で「force-push が要る」状況に行き着いた場合は前提が崩れているサインなので、押し切らずユーザーに報告する

## 手順

### 1. base branch を特定する

現在のブランチに紐づく PR があれば、その base branch を使う。

```bash
gh pr view --json baseRefName,number -q '"#\(.number) -> \(.baseRefName)"'
```

PR がまだない場合 (`gh pr view` が PR 不在を示すメッセージで失敗した場合) は、リポジトリの default branch にフォールバックする。認証エラーなど別の理由で失敗した場合はフォールバックせず、エラー内容をユーザーに報告する。

```bash
git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
```

フォールバックした場合は、その旨を一言報告する (確認は不要。何を base として扱ったかを透明にするため)。

### 2. base branch を取り込む

```bash
git fetch origin <base>
git merge origin/<base>
```

#### conflict が発生した場合

```bash
git status --porcelain | grep '^UU\|^AA\|^DD\|^AU\|^UA\|^DU\|^UD'
```

で conflict しているファイルを確認し、それぞれ解決する。

- 双方の変更の意図をそのファイルの周辺コードやコミットメッセージから読み取り、両方を活かせる形に統合する
- lockfile やビルド成果物などの生成ファイルは手で編集せず、再生成コマンドがあればそれを使う
- 判断に迷っても作業を止めずに最も合理的な解決を選んで進める

解決したら:

```bash
git add <resolved files>
git commit --no-edit
```

### 3. 追従が必要な変更がないか確認する

conflict なく取り込めた場合 (fast-forward や自動 merge も含む) でも、base 側の変更が自分の作業に影響しないとは限らない。何が入ってきたかを確認する。

```bash
git log HEAD@{1}..origin/<base> --oneline
git diff HEAD@{1} HEAD --stat
```

`HEAD@{1}` は取り込み前 (手順2の直前) の HEAD を指す。

プロジェクトの CLAUDE.md や README 等に「新規ファイル追加時はマッピング定義を更新する」「ビルドが要る設定変更後は再デプロイする」といった運用ルールがあれば、それに従って対応する。ルールが明文化されていないプロジェクトでは、依存関係ファイル (lockfile など) の変更で再インストールが要る、マイグレーションの追加で実行が要る、といった観点で確認する。

対応が必要なければそのまま次に進む。対応した場合は何をしたか報告する。

### 4. push する

```bash
git push
```

force-push は使わない。通常の push が reject される場合 (remote に自分の知らないコミットがある等) は、force-push で押し切らずユーザーに報告して指示を仰ぐ。
