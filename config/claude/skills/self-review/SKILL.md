---
name: self-review
description: 差分に対する self-review を複数の専門 reviewer で並列実行する。Use this skill when reviewing a staged diff before committing, a branch diff before pushing, or any multi-dimension review of code changes.
---

# Self Review

差分レビューを専門 reviewer へ分割して並列実行し、結果を統合する。
reviewer の選択順、agent、trigger、reference は `reviewers.yaml` を唯一の定義とする。

## いつ使うか

- コミット前 (`git diff --cached`) のレビュー
- push 前 (`git diff @{u}..HEAD` または `git diff origin/<base>..HEAD`) のレビュー
- PR 作成・更新時のレビュー

!`runok exec -- '~/.claude/skills/self-review/scripts/render-backend-instructions'`

## 結果集約

base reviewer の評価を 13 観点の通し番号順に並べ、起動した conditional reviewer の評価をその後へ追加する。
未起動の conditional reviewer は出力しない。

### Dedup ルール

指摘 ID と症状要約を key に以下を適用する:

1. 同一 file:line かつ同一 issue は 1 件にマージし、両方の reviewer 名を記録する
2. 同一 file:line でも異なる issue は別件として残し、`co-located` を付ける
3. 同一 issue でも location が異なる場合は別件として残し、互いを cross-reference する
4. severity が異なる場合は高い方を採用する

## 出力形式

以下の 3 セクションをこの順序で必ず出す。
指摘がなくても全 header を出す。

### 1. 観点別評価

base reviewer の 13 観点を全件出力し、各項目に以下のいずれかを付ける:

- `✅`: 壊れる可能性を検討した上で問題なし
- `⚠️ N/A`: この diff に構造上関係しない。理由を 1 行で付ける
- `⚠️ 未評価`: reviewer が retry 後も失敗した
- `🔴` / `🟡`: 指摘あり。複数ある場合は最重要 marker と総件数を併記する

```text
## 観点別評価

1. 正しさ: <marker> <summary>
2. セキュリティ: <marker> <summary>
3. パフォーマンス: <marker> <summary>
4. 並行性: <marker> <summary>
5. エラーハンドリング: <marker> <summary>
6. 互換性: <marker> <summary>
7. 可観測性: <marker> <summary>
8. 保守性: <marker> <summary>
9. テスト容易性: <marker> <summary>
10. ドキュメント整合性: <marker> <summary>
11. コメントの質: <marker> <summary>
12. プロジェクト規約遵守: <marker> <summary>
13. リファクタリング機会: <marker> <summary>
```

起動した conditional reviewer の評価は manifest / result の reviewer 順で続ける。

### 2. 指摘詳細

`🔴` / `🟡` の指摘を重要度順に並べる。
指摘がなければ `指摘なし` と出力する。
同じ症状が多数ある場合は代表的な 1-2 件に絞り、残りの件数を注記する。

### 3. サマリ

```text
## Summary

- Critical: <count>
- Warning: <count>
- Files reviewed: <count>
```
