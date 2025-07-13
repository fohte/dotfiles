# Decompose Task

Break down a task from fohte/tasks repository into manageable subtasks. This command helps structure work by creating either simple TODOs or separate sub-tasks based on complexity.

**Important**: All tasks are managed in Japanese language. Use Japanese for all task-related content.

## 1. Analyze task complexity

First, run `~/.claude/commands/task-analyze.md` if you haven't already, then assess:
- Number of distinct features or components involved
- Dependencies between tasks
- Estimated effort for each part
- Whether tasks can be done in parallel

## 2. Default strategy: Use TODOs

**Always start with TODOs first**. Sub-tasks can be created later if needed.

Update the task body with TODOs:
```bash
# First get the current body (task view now returns JSON)
task view <task-number> | jq -r '.body' > .claude/tmp/task-<task-number>-body.md

# Edit the file to add TODOs section
# Add the following at the end of the file:
# ## TODOs
#
# - [ ] 既存の実装を調査
# - [ ] 設計案を作成
# - [ ] コア機能を実装
# - [ ] テストを追加
# - [ ] ドキュメントを更新

# Update the task
task edit <task-number> --body "$(cat .claude/tmp/task-<task-number>-body.md)"
```

For complex tasks, create nested TODOs:
```markdown
## TODOs

- [ ] 大きなタスク1
  - [ ] サブタスク1-1
  - [ ] サブタスク1-2
  - [ ] サブタスク1-3
- [ ] 大きなタスク2
  - [ ] サブタスク2-1
  - [ ] サブタスク2-2
```

## 3. (Optional) Create sub-tasks later if needed

**Note**: Sub-tasks should only be created when:
- A TODO item becomes too large and needs independent tracking
- Multiple people need to work on different parts
- A specific part needs its own discussion thread

If you later decide a TODO needs to be a sub-task:

```bash
# Create a new sub-task from a TODO item
task create \
  --title "<TODOから抽出したタイトル>" \
  --body "## Why

- from: https://github.com/fohte/tasks/issues/<parent-number>
- <このTODOを独立させる理由>

## What

<具体的なタスクの説明>

### TODOs

- [ ] <詳細なステップ>
"

# Link to parent
task add-sub <parent-number> <sub-task-number>

# Update parent task's TODO to reference the sub-task
# - [ ] 元のTODO → - [ ] 元のTODO (→ #<sub-task-number>)
```

## 4. Save decomposition for reference

Save the TODO structure to `.claude/tmp/task-<number>-todos.md` for future reference:

```bash
# Extract just the TODOs section
task view <number> | jq -r '.body' | sed -n '/## TODOs/,$p' > .claude/tmp/task-<number>-todos.md
```

## Best practices

- Start with TODOs, create issues only when necessary
- Keep TODO items actionable and specific (in Japanese)
- Use nested TODOs for logical grouping
- Don't over-decompose - aim for 3-7 main TODO items
- Update TODOs as work progresses (mark completed, add new ones)
- Write all descriptions and comments in Japanese

## Output example
```
タスク #123 のTODOリストを更新しました。

## TODOs
- [ ] JWTトークン生成の実装
  - [ ] JWT ライブラリの選定
  - [ ] トークン生成関数の実装
  - [ ] テストの作成
- [ ] ログイン/ログアウトエンドポイントの作成
- [ ] 認証ミドルウェアの追加
- [ ] フロントエンド認証フローの更新

TODOリストは .claude/tmp/task-123-todos.md に保存されました。
```
