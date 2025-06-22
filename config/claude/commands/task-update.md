# Update Task

Update task status, progress, and documentation in fohte/tasks repository. This command handles progress tracking, comment updates, and TODOs maintenance.

**Important**: All tasks are managed in Japanese language. Use Japanese for all task-related content.

## 1. Update task progress

### Add a progress comment

Document work progress with detailed comments:

```bash
task comment <task-number> --body "## 〜〜をした

<具体的になにをやったか記述>

### Next Actions

- 次なにやるか
"
```

## 2. Update TODOs in task body

### Get current task body

```bash
# Save current body to edit
task view <task-number> | grep -A 1000 "^##" > .claude/tmp/task-body.md
```

### Update TODO items

Edit the saved body to mark completed items:

```markdown
## TODOs
- [x] 既存の実装を調査
- [x] 設計案を作成
- [x] コア機能を実装 (https://github.com/<owner>/<repo>/pull/<task-number>)
- [ ] テストを追加 (https://github.com/<owner>/<repo>/pull/<task-number>)
- [ ] ドキュメントを更新 (https://github.com/<owner>/<repo>/pull/<task-number>)
```

PR リンクがあるときは貼ること

### Apply the update

```bash
task edit <task-number> --body "$(cat .claude/tmp/task-body.md)"
```

## 3. Add or update todo lists

### Update TODOs section
```bash
# Get current task body (task view now returns JSON)
task view <task-number> | jq -r '.body' > .claude/tmp/task-body.md

# Edit the file to add new TODOs to the existing TODOs section
# Add new items like:
# - [ ] 認証モジュールのリファクタリング
# - [ ] レート制限の追加
# - [ ] APIドキュメントの更新

# Apply the update
task edit <task-number> --body "$(cat .claude/tmp/task-body.md)"
```

### Convert findings to actionable items
When discovering new requirements during work:

1. First, add a comment documenting the new requirements:
```bash
task comment <task-number> --body "## 追加でやるべきこと

- **タスク**: <説明>
   - 理由: <なぜ必要か>
   - 影響: <何に影響するか>
- **タスク**: <説明>
   - 理由: <理由>
   - 影響: <影響範囲>
"
```

2. Then, update the task body to include these items in the TODOs section:
```bash
# Get current task body
task view <task-number> | grep -A 1000 "^##" > .claude/tmp/task-body.md

# Edit the file to add the new tasks to the TODOs section

# Apply the update
task edit <task-number> --body "$(cat .claude/tmp/task-body.md)"
```

## 6. Document decisions and changes

### Technical decisions
```bash
task comment <task-number> --body "## 技術的決定

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
task comment <task-number> --body "## スコープ変更

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
- Keep TODOs in task body, detailed updates in comments
- Link to relevant commits, PRs, and related tasks
- Document decisions that affect future work
- Update labels to reflect current state
- Write all content in Japanese for consistency
- Notify stakeholders of significant changes with @mentions

## Examples

### Output example
```
タスク #123 の進捗を更新しました。

更新内容:
- TODOs: 3/5 項目完了
- ラベル: "作業中" を追加
- 進捗コメントを追加

次のステップ: テストの実装
```
