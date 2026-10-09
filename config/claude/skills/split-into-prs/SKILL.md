---
name: split-into-prs
description: Split a task into a set of small, single-concern PRs that can be implemented in parallel by independent sessions. Use this skill whenever the user asks to break down, decompose, or split a task ("タスク分解して", "PR 分割して", "分割して並列で進めたい", "break this down", "split into PRs"), and always before delegating to a repository whose `repo.direct_commit` is not true, even if the user doesn't ask to split (skip only when the user has already specified or approved the split). Also trigger when the user describes a feature or refactor large enough that a single PR would be hard to review, even if they don't say "split".
---

# タスクを PR 単位に分割する

大きなタスクを、独立して実装・レビュー・merge できる PR 単位に分割する。実装はしない。分割結果を出すところまでが担当範囲。

## 分割の 3 基準

優先度の高い順。衝突したら上が勝つ。

1. **1 PR = 1 関心事**: 1 つの PR は 1 つの理由で存在する。レビュアーが「この PR は何のためのものか」を一文で言えない分割は失敗している
2. **context が小さい**: 委任先が実装のために読む必要のあるファイル・前提知識が少ないほどよい。分割の目的はコード行数を減らすことではなく、**必要な前提知識を減らすこと**
3. **並列に進められる**: PR 同士が同じファイルの同じ箇所を触らず、互いの成果物を待たない

関心事を半分に切って context を小さくしても、両方の PR を読まないと理解できなくなるだけで context は減らない。1 が 2 に勝つのはこのため。

## 手順

1. **現状を調べる**: 影響範囲のファイルと既存の構造を実際に読む。想像で分割しない
2. **共通の土台を探す**: 型定義、スキーマ、インターフェース、設定の受け皿など、複数の変更が同時に必要とするものを特定する。これが最初の 1 PR になり、以降が並列化できるかを決める
3. **関心事ごとに束ねる**: 「同じ理由で一緒に変わるもの」を 1 PR にまとめる
4. **依存を見る**: PR 間の前後関係を確認し、今すぐ着手できるものと、先行 PR の merge を待つものを分ける
5. **各 PR が単独で成立するか検証する**: それだけ merge しても壊れず、それだけ revert しても戻せるか。成立しないなら隣の PR と統合する

## 出力フォーマット

以下の形式で出力する。委任先へのプロンプトはここでは書かない (delegate の担当)。

```markdown
## Batch 1 (今すぐ並列で着手可能)

### PR 1: <一文で言える目的>

- 変更範囲: <触るファイル / ディレクトリ>
- ゴール: <何が達成されていればよいか>
- 依存: なし

### PR 2: ...

## Batch 2 (Batch 1 の merge 後)

### PR 3: <目的>

- 依存: PR 1 (<何を待つのか>)
```

分割後、そのまま委任に進む場合は delegate に渡す。delegate は 1 委任 = 1 PR なので、着手できるのは Batch 1 のみ。後続 Batch は先行 PR が merge されてから改めて委任する。

## tq チェックリストへの記録

分割案を提示した時点では tq を更新しない。ユーザーが案を承認した後、`track-in-tq` が選んだ作業タスクの ID がある場合だけ、PR の一覧をチェックリストに記録する。タスクが無い場合はチャットに案を出すだけにする。

1. `tq checklist list <taskId>` で既存のチェックリストを確認する。名前が `実装` のものが無ければ `tq checklist create <taskId> --name 実装` で作り、あれば既存のチェックリストを更新する
2. 承認された分割案に残る PR 項目は既存の葉項目 ID を保ち、本文と note を更新する。Batch の構成が変わったら `tq checklist item move` で親項目または root に移す。merged の PR 項目を残す場合はその checked 状態を保つ
3. 新しい Batch が複数なら `Batch 1` などの親項目を作り、その下に各 PR 項目を追加する。Batch が 1 つなら親項目を作らず、PR 項目を直接並べる
4. 古い PR 項目は、承認された分割案に対応せず、その ID を渡した委任も実行中でない場合に削除する。項目に PR が紐付いている場合は、項目の `githubLinkId` と `tq task get <taskId>` の `githubLinks[].id` を対応させて状態を確認し、open の間は項目を残す。実行中の委任や open の PR を新しい案から外す場合は、完了またはキャンセルしてから項目を削除する。`tq checklist item delete <itemId>` は子項目も削除するため、Batch 親は子がすべて削除対象のときだけ削除する
5. PR 項目の本文は `PR 1: <目的>` とし、note に `変更範囲`、`ゴール`、`依存` を記録する。本文は 1 行にし、note に長い内容を書く
6. `tq checklist list <taskId>` で親子関係と内容を確認する。各 PR の葉項目 ID を控え、delegate に対応する ID を渡す。Batch の親項目 ID は渡さない

親項目と PR 項目は `tq checklist item add <checklistId> <content>` で作る。複数 Batch の場合は PR 項目に `--parent <batchItemId>` を付け、単一 Batch では省略する。既存項目は `tq checklist item update` で本文や note を更新し、必要なら `tq checklist item move` で移動する。PR 項目の note は一時ファイルを `--note-file <path>` で渡す。すべての `tq` 呼び出しで `--author <model>` を指定し、長文の受け渡しは `tq` skill に従う。コマンドの引数は `tq checklist item add --help` など、該当する subcommand の `--help` で確認する。

## アンチパターン

- **PR ではなく commit を分ける**: PR は squash merge されるため、1 PR 内でいくら commit を分けても merge 後の履歴には 1 つしか残らない。関心を分ける単位は commit ではなく PR
- **フェーズ分割で終わらせる**: 「Phase 1: 実装 / Phase 2: テスト / Phase 3: ドキュメント」は関心事ではなく作業工程の分割。並列化できず、Phase 1 だけ merge しても価値が出ない
- **細かく切りすぎる**: 単独では merge する意味がない PR は分割ではなく分断。レビューと merge の往復コストが実装より重くなる
- **依存を無視して全部 Batch 1 に入れる**: 並列で走らせた結果 conflict と手戻りが出る。並列数より、待ちが発生しないことのほうが価値が高い
- **調べずに分割する**: ファイルを読まずに立てた分割は、実装が始まってから境界が崩れる
