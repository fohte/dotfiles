# Complete Task

Close a task in fohte/tasks repository with proper documentation of outcomes, learnings, and final status. This command ensures tasks are completed with comprehensive closure.

**Important**: All tasks are managed in Japanese language. Use Japanese for all task-related content.

## 1. Verify completion readiness

### Check all tasks are done
```bash
# View task to verify all checkboxes are checked
gh issue view <task-number> --repo fohte/tasks

# For tasks with sub-tasks, verify all are closed
gh issue list --repo fohte/tasks --search "親タスク #<task-number>" --state open
```

### Ensure all related work is merged
```bash
# Check for open PRs referencing this task
gh pr list --search "<task-number>"
```

## 2. Create completion summary

Write a comprehensive closure comment:

```bash
gh issue comment <task-number> --repo fohte/tasks --body "## タスク完了サマリー

### 実現した内容
- <主な成果1>
- <主な成果2>
- <追加の成果物>

### 実装詳細
- **アプローチ**: <解決策の簡潔な説明>
- **主な変更点**:
  - <ファイル/コンポーネント>: <変更内容>
  - <ファイル/コンポーネント>: <変更内容>
- **関連PR**: #<pr1>, #<pr2>

### テストと検証
- <どのようにテストしたか>
- <パフォーマンスへの影響（あれば）>
- <対応したエッジケース>

### 成果と影響
- <ビジネス/ユーザーへの影響>
- <技術的な改善点>
- <パフォーマンスの向上>

### 学びと気づき
- <うまくいったこと>
- <直面した課題とその解決方法>
- <次回改善できる点>

### フォローアップ項目
- <新たに作成したタスク>: #<task-number>
- <将来の改善案>
- <技術的負債の記録>

### ドキュメント更新
- <更新したドキュメント>: <リンクまたは参照>
- <READMEの変更>: <追加内容>
- <APIドキュメント>: <記載内容>

---
✅ このタスクは完了し、クローズする準備ができています。
"
```

## 3. Update final TODOs status

If using TODOs, ensure all items are marked complete:

```bash
# Get current body
gh issue view <task-number> --repo fohte/tasks --json body -q .body > .claude/tmp/task-final-body.md

# Verify all checkboxes are [x], then update if needed
gh issue edit <task-number> --repo fohte/tasks --body-file .claude/tmp/task-final-body.md
```

## 4. Archive work artifacts

Save important context and decisions:

```bash
# Create completion archive
mkdir -p .claude/tmp/completed-tasks/
cat > .claude/tmp/completed-tasks/task-<task-number>-complete.md << 'EOF'
# 完了: Task #<task-number> - <title>

完了日: $(date)

## サマリー
<達成した内容の最終まとめ>

## 重要な決定事項
<技術的または設計上の重要な決定>

## コード参照
- メイン実装: <file:line>
- テスト: <file:line>
- ドキュメント: <file>

## メトリクス
- 所要時間: <推定時間>
- 変更ファイル数: <count>
- コード行数: <追加/削除>

## 得られた教訓
<今後同様のタスクで活かせること>
EOF
```

## 5. Close the task

### Close with final comment
```bash
# Close with reference to completion summary
gh issue close <task-number> --repo fohte/tasks --comment "タスクが正常に完了しました。詳細は上記の完了サマリーをご覧ください。

ご協力いただいた皆様、ありがとうございました！ 🎉"
```

### Close with specific reason
```bash
# If completed as part of a PR
gh issue close <task-number> --repo fohte/tasks --comment "PR #<pr-number> で完了しました。"

# If completed by sub-tasks
gh issue close <task-number> --repo fohte/tasks --comment "すべてのサブタスクが完了しました：
- #<sub1> ✅
- #<sub2> ✅
- #<sub3> ✅

親タスクを完了とします。"
```

## 6. Update related tracking

### Update parent tasks if this was a sub-task
```bash
gh issue comment <parent-task-number> --repo fohte/tasks --body "サブタスク #<task-number> が完了しました。

<達成内容の簡単なまとめ>

詳細は #<task-number> をご覧ください。"
```

### Update project boards or milestones
```bash
# Remove from active milestone if needed
gh issue edit <task-number> --repo fohte/tasks --milestone ""
```

## Best practices

- Always document outcomes, not just that work is "done"
- Include specific examples and metrics where possible
- Credit contributors with @mentions
- Link to all related PRs, commits, and documentation
- Save learnings for future reference
- Create follow-up tasks for any discovered work
- Be thorough but concise in summaries
- Include both technical and user-facing impacts
- Write all content in Japanese for consistency

## Examples

### Example 1: Feature completion
```bash
gh issue comment 789 --repo fohte/tasks --body "## 機能完成: ユーザー認証システム

### 実現した内容
- リフレッシュトークン付きJWT認証
- レート制限付きログイン/ログアウトエンドポイント
- メール確認付きパスワードリセットフロー
- セッション管理ミドルウェア

### 技術的影響
- 3つの新しいAPIエンドポイントを追加
- セッションストレージにRedisを実装
- 認証モジュールのテストカバレッジ98%

### ユーザーへの影響
- ユーザーは安全にログインし、セッションを維持できる
- パスワードリセットでサポートチケットが削減
- セッションタイムアウトでセキュリティが向上

### 学び
- Redisのセットアップは想定より複雑 - Wikiに文書化
- レート制限戦略は本番環境でのモニタリングが必要
- 将来的にOAuth統合を検討すべき

### フォローアップ
- #790 でOAuth統合を作成
- #791 で管理者ユーザー管理を作成

認証マイルストーンが完了しました！ 🚀"

gh issue close 789 --repo fohte/tasks
```

### Example 2: Bug fix completion
```bash
gh issue comment 456 --repo fohte/tasks --body "## バグ修正: データエクスポートのメモリリーク

### 原因
CSVエクスポートモジュールで閉じられていないファイルストリームによるメモリリーク。

### 解決策
- finallyブロックで適切なストリームクリーンアップを実装
- 大規模エクスポート用のメモリモニタリングを追加
- ストリーミング用の最大チャンクサイズを設定

### 検証
- 100万行以上のエクスポートでもメモリ使用量が一定
- リグレッション防止のための統合テストを追加
- ステージング環境で48時間モニタリング

### 影響
- エクスポート失敗に関する顧客の苦情を解決
- エクスポート中のサーバーメモリ使用量を約60%削減
- より大規模なデータエクスポートが可能に

v2.3.4で本番環境にデプロイ済み。"

gh issue close 456 --repo fohte/tasks --comment "バグ修正が完了し、デプロイされました。モニタリングで安定したメモリ使用量を確認。"
```

### Output example
```
タスク #123 を完了しました。

完了内容:
- ユーザー認証システムの実装
- 全サブタスク完了
- ドキュメント更新済み

学んだこと:
- JWT実装のベストプラクティス
- Redis統合のパターン

フォローアップタスク作成済み: #124, #125
```
