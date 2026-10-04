---
name: sync-base-branch
description: Sync a PR's base branch when explicitly requested or when a conflict or base-caused CI failure requires it. Merge once per explicit request even with no conflict; after pushing, base advances trigger another merge only when the PR becomes CONFLICTING. Resolve conflicts, check for follow-up work, push, and confirm CI. Use this skill for base-branch syncs instead of running git merge/push manually.
---

# Sync base branch

ユーザーの明示依頼、または自律 sync の条件を満たす場合に base branch (master/main など) を取り込み、conflict を解消し、追従が必要な変更を確認して push し、CI を確認する。

## 方針

- **merge のみを使う。rebase はしない。** rebase は force-push を要求するが、force-push は共有履歴や他者の作業を壊しうる破壊的操作であり、このスキルでは行わない。merge なら通常の push で完結する
- conflict の解消と CI 失敗の修正はユーザーに確認せず自律的に進める。判断根拠は最後の報告にまとめ、ユーザーが後から検証できるようにする
- 途中で「force-push が要る」状況に行き着いた場合は前提が崩れているサインなので、押し切らずユーザーに報告する

## merge する条件

- 明示的な sync 依頼があれば conflict の有無にかかわらず 1 回 merge する
- それ以外は、PR の `mergeable` が `CONFLICTING` のとき (直前に merge 済みでも。conflict が残ったままでは PR を merge できないため)、またはまだ merge していない状態で CI 失敗が base branch の変更に起因すると確認できたときだけ merge する。base が進んだことや PR が base より遅れていることだけでは merge しない
- `mergeable` が `UNKNOWN` の場合は 3 秒後に再取得する (最大 3 回)。状態が確定しなければ merge せず、その旨を報告して終了する

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

### 2. merge 条件を確認して base branch を取り込む

明示的な sync 依頼がない場合は、`gh pr view --json mergeable` で PR の状態を確認し、上記の条件に従う。条件を満たさない場合はここで終了する。

明示的な sync 依頼がある場合は、状態確認を省いて merge を 1 回試みる。

```bash
git rev-parse HEAD > /tmp/sync-base-branch-pre-merge-sha
git fetch origin <base>
git merge origin/<base>
```

SHA をファイルに退避するのは、"Already up to date." の場合 `HEAD` も reflog も動かず、`HEAD@{1}` のような相対参照では取り込み前の状態を指せないため。

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
PRE_MERGE_SHA=$(cat /tmp/sync-base-branch-pre-merge-sha)
git log $PRE_MERGE_SHA..origin/<base> --oneline
git diff $PRE_MERGE_SHA HEAD --stat
```

プロジェクトの CLAUDE.md や README 等に「新規ファイル追加時はマッピング定義を更新する」「ビルドが要る設定変更後は再デプロイする」といった運用ルールがあれば、それに従って対応する。ルールが明文化されていないプロジェクトでは、依存関係ファイル (lockfile など) の変更で再インストールが要る、マイグレーションの追加で実行が要る、といった観点で確認する。

対応が必要なければそのまま次に進む。対応した場合は何をしたか報告する。

### 4. push する

```bash
git push
```

force-push は使わない。通常の push が reject される場合 (remote に自分の知らないコミットがある等) は、force-push で押し切らずユーザーに報告して指示を仰ぐ。

### 5. CI check する

手順 1 で PR が見つかっていた場合、push 後に CI の結果を確認する。

```bash
gh pr checks --watch
```

push 直後は check-run が GitHub 側にまだ登録されておらず "no checks reported" で失敗することがある。その場合は数秒待って同じコマンドを再実行する。

全 check が完了するまで待つ。失敗した check があれば原因を修正して commit と push を行い、check を再確認する。base branch は上記の merge 条件に従う。

全 check が完了したら `gh pr view --json mergeable -q .mergeable` を再取得する (`UNKNOWN` の扱いは merge 条件と同じ)。`gh pr checks` の出力には conflict が現れないため。`CONFLICTING` なら手順 2 に戻る。

手順 1 で PR が見つからなかった場合 (default branch にフォールバックした場合) は、確認対象の PR がないためこの手順はスキップする。
