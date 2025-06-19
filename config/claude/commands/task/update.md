# Update Task

Update task status, progress, and documentation in fohte/tasks repository. This command handles progress tracking, comment updates, and checklist maintenance.

**Important**: All tasks are managed in Japanese language. Use Japanese for all task-related content.

## 1. Update task progress

### Add a progress comment

Document work progress with detailed comments:

```bash
gh issue comment <task-number> --repo fohte/tasks --body "## 進捗報告

### 完了した内容
- <完了した作業>
- <具体的な成果>

### 現在作業中
- <現在進めている作業>

### 次のステップ
- <次に予定している作業>

### ブロッカー（もしあれば）
- <遭遇している問題>
"
```

### Quick status update

For brief updates:
```bash
gh issue comment <task-number> --repo fohte/tasks --body "ステータス: <簡潔な状況更新>"
```

## 2. Update checklists in task body

### Get current task body
```bash
# Save current body to edit
gh issue view <task-number> --repo fohte/tasks --json body -q .body > .claude/tmp/task-body.md
```

### Update checklist items
Edit the saved body to mark completed items:
```markdown
## タスクリスト
- [x] 既存の実装を調査 ✓ 完了
- [x] 設計案を作成 ✓ 完了
- [ ] コア機能を実装 ← 現在作業中
- [ ] テストを追加
- [ ] ドキュメントを更新
```

### Apply the update
```bash
gh issue edit <task-number> --repo fohte/tasks --body-file .claude/tmp/task-body.md
```

## 3. Add or update todo lists

### Add new todo section
```bash
# Append new todos to existing body
gh issue view <task-number> --repo fohte/tasks --json body -q .body > .claude/tmp/task-body.md
cat >> .claude/tmp/task-body.md << 'EOF'

## 追加で発見されたタスク
- [ ] 認証モジュールのリファクタリング
- [ ] レート制限の追加
- [ ] APIドキュメントの更新
EOF

gh issue edit <task-number> --repo fohte/tasks --body-file .claude/tmp/task-body.md
```

### Convert findings to actionable items
When discovering new requirements during work:
```bash
gh issue comment <task-number> --repo fohte/tasks --body "## 新たに特定された要件

作業中に以下の追加タスクが必要であることが判明しました：

1. **タスク**: <説明>
   - 理由: <なぜ必要か>
   - 影響: <何に影響するか>

2. **タスク**: <説明>
   - 理由: <理由>
   - 影響: <影響範囲>

これらは現在のタスクに追加すべきか、別タスクとして作成すべきか検討が必要です。"
```

## 4. Update labels and metadata

### Update labels based on progress
```bash
# Add/remove labels
gh issue edit <task-number> --repo fohte/tasks --add-label "作業中"
gh issue edit <task-number> --repo fohte/tasks --remove-label "準備完了"

# Update priority
gh issue edit <task-number> --repo fohte/tasks --remove-label "優先度:低" --add-label "優先度:高"
```

### Assign or reassign
```bash
gh issue edit <task-number> --repo fohte/tasks --add-assignee @me
gh issue edit <task-number> --repo fohte/tasks --add-assignee username
```

## 5. Link related work

### Reference commits and PRs
```bash
gh issue comment <task-number> --repo fohte/tasks --body "関連する作業:
- コミット: <sha> - <説明>
- PR: #<pr-number> - <タイトル>
- 関連タスク: #<task-number> - <コンテキスト>
"
```

### Update sub-task progress
For parent tasks with sub-tasks:
```bash
gh issue comment <task-number> --repo fohte/tasks --body "## サブタスクの進捗

- #124 - ✅ 完了: JWTトークン生成
- #125 - 🔄 作業中: ログイン/ログアウトエンドポイント (80% 完了)
- #126 - ⏳ 未着手: 認証ミドルウェア
- #127 - ⏳ ブロック中: バックエンドの完了待ち

全体進捗: 2/4 サブタスク完了 (50%)
"
```

## 6. Document decisions and changes

### Technical decisions
```bash
gh issue comment <task-number> --repo fohte/tasks --body "## 技術的決定

### 背景
<この決定に至った経緯>

### 検討した選択肢
1. <選択肢1>: <メリット/デメリット>
2. <選択肢2>: <メリット/デメリット>

### 決定内容
<選択した内容とその理由>

### 影響
<実装への影響>
"
```

### Scope changes
```bash
gh issue comment <task-number> --repo fohte/tasks --body "## スコープ変更

### 当初のスコープ
<最初に計画していた内容>

### 変更後のスコープ
<新しいスコープ>

### 変更理由
<なぜ変更が必要か>

### スケジュールへの影響
<完了時期への影響>
"
```

## Best practices

- Update regularly but avoid noise - batch small updates
- Be specific about progress percentages and blockers
- Keep checklists in task body, detailed updates in comments
- Use emoji sparingly for status: ✅ ❌ 🔄 ⏳ 🚧
- Link to relevant commits, PRs, and related tasks
- Document decisions that affect future work
- Update labels to reflect current state
- Write all content in Japanese for consistency
- Notify stakeholders of significant changes with @mentions

## Examples

### Example 1: Daily progress update
```bash
gh issue comment 123 --repo fohte/tasks --body "## 日次更新 - $(date +%Y-%m-%d)

### 本日の完了内容
- ユーザー認証エンドポイントを実装
- 入力バリデーションを追加
- 認証モジュールのユニットテストを作成

### 明日の予定
- 統合テスト
- エラーハンドリングの改善
- ドキュメントの更新

現在ブロッカーはありません。"
```

### Example 2: Updating complex checklist
```bash
# First get the current body
gh issue view 456 --repo fohte/tasks --json body -q .body > .claude/tmp/task-456-body.md

# Edit to update progress
# Then apply update
gh issue edit 456 --repo fohte/tasks --body-file .claude/tmp/task-456-body.md

# Add progress comment
gh issue comment 456 --repo fohte/tasks --body "チェックリストを更新: 5/8 タスク完了 (62.5%)。現在API統合に取り組んでいます。"
```

### Output example
```
タスク #123 の進捗を更新しました。

更新内容:
- チェックリスト: 3/5 項目完了
- ラベル: "作業中" を追加
- 進捗コメントを追加

次のステップ: テストの実装
```
