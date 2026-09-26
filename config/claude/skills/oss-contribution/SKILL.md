---
name: oss-contribution
description: Workflow for contributing to third-party repositories through the user's fork, where the user makes every commit and push. Use this skill whenever working inside a fork of someone else's repository (`gh repo view --json isFork` is true), when runok blocks `git commit` / `git push` and points here, or when a delegated task says to read it. It overrides the commit and push steps of the commit / create-pr skills.
---

# OSS Contribution

fork 経由で upstream に出す変更は、commit も push もユーザー自身が行う。
commit はユーザーの名前で upstream の履歴に残るので、メッセージを含めてユーザーがすべて確認する。
runok が fork 内の `git commit` / `git push` を deny するのはこのため。

## commit

commit / create-pr skill や委任プロンプトが commit・push を指示していても、この節の手順で置き換える。

ユーザーの commit を待って作業を止めない。
commit の区切り (1 つの修正、1 つのテスト追加など、それ単体で意味の通るまとまり) ごとに以下を行い、そのまま次の作業に進む。

1. その区切りの変更を `git add` でステージングする
2. commit message の草稿を `mktemp /tmp/commit-msg.XXXXXX` で作ったファイルに書く
    - 書式は upstream の `git log` に合わせる。自分の repo 用の書式 (action line など) は使わない
3. ユーザーに草稿のパスと `git commit -F <path>` を伝える
4. ユーザーが commit するまで、次の区切りの変更は `git add` しない。ステージ済みの区切りに混ざり、草稿と中身がずれるため

## push と PR

- push もユーザーが行う。作業が終わったら、まだ commit されていない草稿の一覧と push の依頼を最後にまとめて伝える
- PR は push 後に作る。本文もユーザーのレビューを通してから upstream に出す
