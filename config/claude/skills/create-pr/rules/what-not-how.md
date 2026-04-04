# What (何を) を書く。How (どのように) は書かない

- **「何が変わるか」を書く**: 変更の効果、ユーザー/システムへの影響
- **「どこをどう変えたか」は書かない**: ファイルパス、行番号、具体的なコード変更

**Title と What の役割分担**: Title は効果を一言で、What は Title をもう少し具体的に説明する (ただし How ではない)。

| ✅ 適切 (What)                         | ❌ 詳細すぎ (How)                                       |
| -------------------------------------- | ------------------------------------------------------- |
| API レスポンスにページネーションを追加 | `getUsers` 関数の戻り値に `nextCursor` フィールドを追加 |
| エラー時のリトライ処理を追加           | `fetch` を `while` ループで囲んで 3 回までリトライ      |

**Title と What の例:**

```markdown
Title: lockFileMaintenance の minimumReleaseAge チェックを無効化する

## What

- `lockFileMaintenance` に対して `minimumReleaseAge` のチェックを無効化し、リリースタイムスタンプが取得できない場合でも automerge が実行されるようにする
```
