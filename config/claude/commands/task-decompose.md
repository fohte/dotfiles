# Decompose Task

Break down a task from fohte/tasks repository into manageable subtasks. This command helps structure work by creating either simple TODOs or separate sub-tasks based on complexity.

**Important**: All tasks are managed in Japanese language. Use Japanese for all task-related content.

## 1. Analyze task complexity

First, run `~/.claude/commands/task-analyze.md` if you haven't already, then assess:
- Number of distinct features or components involved
- Dependencies between tasks
- Estimated effort for each part
- Whether tasks can be done in parallel

## 2. Choose decomposition strategy

### For simple tasks (use TODOs)

When tasks are:
- Small and sequential
- All part of a single coherent change
- Can be completed in one work session

Update the task body with TODOs:
```bash
# First get the current body
task view <task-number> | grep -A 1000 "^##" > /tmp/task-body.md

# Edit the file to add TODOs section
echo "\n## TODOs\n\n- [ ] 既存の実装を調査\n- [ ] 設計案を作成\n- [ ] コア機能を実装\n- [ ] テストを追加\n- [ ] ドキュメントを更新" >> /tmp/task-body.md

# Update the task
task edit <task-number> --body "$(cat /tmp/task-body.md)"
```

### For complex tasks (use sub-tasks)

When tasks are:
- Large and independent
- Require different expertise
- Can be worked on in parallel
- Need separate tracking

## 3. Create sub-tasks for complex work

For each major component, create a sub-task:

```bash
# Create a new sub-task
task create \
  --title "<サブタスクのタイトル>" \
  --body "## Why

- from: https://github.com/fohte/tasks/issues/<parent-number>

<親タスクからの関連情報>

## What

<具体的なタスクの説明>
<何をもって完了とするか>

### TODOs

- [ ] ...
"
```

## 4. Link sub-tasks to parent using GitHub sub-issues

After creating each sub-task, link it to the parent using the sub-issues feature:

```bash
# Add sub-task to parent issue
task add-sub <parent-number> <sub-task-number>
```

You can also view the hierarchy:

```bash
# View the task hierarchy
task tree <parent-number>
```

## 5. Create tracking structure

Save the decomposition plan to `.claude/tmp/task-<number>-decomposition.md`:

```markdown
# タスク分解: Task #<number>

## 戦略: <checklist|sub-tasks|mixed>

## タスク内訳

### タスク 1: <名前>
- 説明: <何をするか>
- タイプ: <checklist-item|sub-task>
- タスク番号: <#number if sub-task>
- 依存関係: <なし|リスト>
- 見積もり工数: <小|中|大>

### タスク 2: <名前>
...

## 実行順序
1. <最初に行うべきタスク>
2. <次のタスク>
...

## 備考
<特別な考慮事項>
```

## Best practices

- Keep subtask titles descriptive but concise (in Japanese)
- Don't over-decompose - aim for 3-7 subtasks
- Consider dependencies when ordering tasks
- Update parent task when sub-tasks are completed
- Write all descriptions and comments in Japanese

## Output example
```
タスク #123 を分解しました。

#123 - 認証システムの実装
├── **#124 - JWTトークン生成の実装** (New)
├── #125 - ログイン/ログアウトエンドポイントの作成
├── **#126 - 認証ミドルウェアの追加** (New)
└── #127 - フロントエンド認証フローの更新

分解計画は .claude/tmp/task-123-decomposition.md に保存されました。
```
