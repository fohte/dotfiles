# Update Task

Update task TODOs and document completed work in fohte/tasks repository.

**Important**: All tasks are managed in Japanese language. Use Japanese for all task-related content.

## Writing Style Guidelines

- **Use casual language**: 敬語は不要（自分用のタスク管理のため）
- **End TODOs with action verbs**: 全てのTODOは「〜する」で終わるようにして、完了条件を明確にする

## Main Functions

### 1. Update TODOs in task body

When working on a task, keep the TODO list in the issue body updated:

```bash
# Get current task body (task view returns JSON)
task view <task-number> | jq -r '.body' > .claude/tmp/task-body.md

# Edit the file to update TODO items:
# - Mark completed items with [x]
# - Add PR links when available
# - Add new TODO items as discovered

# Apply the update
task edit <task-number> --body "$(cat .claude/tmp/task-body.md)"
```

Example TODO format:
```markdown
## TODOs
- [x] 既存の実装を調査する
- [x] 設計案を作成する
- [x] コア機能を実装する (https://github.com/<owner>/<repo>/pull/<pr-number>)
- [ ] テストを追加する
- [ ] ドキュメントを更新する
```

### 2. Add completion comment for each TODO

When completing a TODO item, add a comment documenting what was done:

```bash
task comment <task-number> --body "## <TODO項目名>

<実際に行った作業の詳細>

- 何を実装/変更したか
- どのような判断をしたか
- 関連するPRやコミット
"
```

Example:
```bash
task comment 123 --body "## コア機能を実装する

Next.js App Router を使って基本的な CRUD 機能を実装した。

- 実装 PR: https://github.com/fohte/example/pull/456
- `/api/items` エンドポイントを作成
- Prisma でデータベース操作を実装
- エラーハンドリングとバリデーションを追加
"
```

## Workflow

1. **Start working on a TODO**: Update status to in-progress
2. **Complete a TODO**:
   - Mark it as completed in the issue body
   - Add a comment with implementation details
3. **Discover new TODOs**: Add them to the TODO list in the issue body
4. **Finish all TODOs**: Consider closing the issue or creating follow-up issues

## Best Practices

- Update TODOs in real-time as you work
- Keep comments focused on what was actually done
- Include relevant links (PRs, commits, documentation)
- Write all content in Japanese
- Batch small TODO updates to avoid excessive edits
