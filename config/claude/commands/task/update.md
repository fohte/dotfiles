# Update Task

Update task status, progress, and documentation in fohte/tasks repository. This command handles progress tracking, comment updates, and checklist maintenance.

**Important**: All tasks are managed in Japanese language. Use Japanese for all task-related content.

## 1. Update task progress

### Add a progress comment

Document work progress with detailed comments:

```bash
gh issue comment <task-number> --repo fohte/tasks --body "## 〜〜をした

<具体的になにをやったか記述>

### Next Actions

- 次なにやるか
"
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
- [x] 既存の実装を調査
- [x] 設計案を作成
- [x] コア機能を実装 (https://github.com/<owner>/<repo>/pull/<task-number>)
- [ ] テストを追加 (https://github.com/<owner>/<repo>/pull/<task-number>)
- [ ] ドキュメントを更新 (https://github.com/<owner>/<repo>/pull/<task-number>)
```

PR リンクがあるときは貼ること

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

^ cat 使わず普通にファイルを update して更新する、という手順にする
あと「追加で発見されたタスク」と section わけるのではなく、TODOs section を更新するだけにする

### Convert findings to actionable items
When discovering new requirements during work:
```bash
gh issue comment <task-number> --repo fohte/tasks --body "## 追加でやるべきこと

- **タスク**: <説明>
   - 理由: <なぜ必要か>
   - 影響: <何に影響するか>
- **タスク**: <説明>
   - 理由: <理由>
   - 影響: <影響範囲>
"
```

^ これ別コメントもしつつ body の TODOS も更新すること

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
- チェックリスト: 3/5 項目完了
- ラベル: "作業中" を追加
- 進捗コメントを追加

次のステップ: テストの実装
```
