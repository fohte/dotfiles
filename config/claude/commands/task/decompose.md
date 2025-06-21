# Decompose Task

Break down a task from fohte/tasks repository into manageable subtasks. This command helps structure work by creating either simple TODOs or separate sub-tasks based on complexity.

**Important**: All tasks are managed in Japanese language. Use Japanese for all task-related content.

## 1. Analyze task complexity

First, run `task-analyze` if you haven't already, then assess:
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
gh issue edit <task-number> --repo fohte/tasks --body "$(cat <<'EOF'
<existing body>

## TODOs

- [ ] 既存の実装を調査
- [ ] 設計案を作成
- [ ] コア機能を実装
- [ ] テストを追加
- [ ] ドキュメントを更新
EOF
)"
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
gh issue create \
  --repo fohte/tasks \
  --title "<サブタスクのタイトル>" \
  --body "## Why

- from: <親タスクの issue URL>

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
gh-sub-issues -R fohte/tasks add <parent-number> <sub-task-number>
```

You can also view the hierarchy:

```bash
# View the task hierarchy
gh-sub-issues -R fohte/tasks tree <parent-number>
```

Optionally, add a comment to track the decomposition:

```bash
gh issue comment <parent-number> --repo fohte/tasks --body "## 作成したサブタスク:
- #<sub-task-1> - <タイトル>
- #<sub-task-2> - <タイトル>
- #<sub-task-3> - <タイトル>

これらのリンクされたタスクで進捗を追跡します。"
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

戦略: サブタスク（複雑なタスクのため）

作成したサブタスク:
- #124: JWTトークン生成の実装
- #125: ログイン/ログアウトエンドポイントの作成
- #126: 認証ミドルウェアの追加
- #127: フロントエンド認証フローの更新

GitHub sub-issues でリンクしました:
- gh-sub-issues -R fohte/tasks add 123 124
- gh-sub-issues -R fohte/tasks add 123 125
- gh-sub-issues -R fohte/tasks add 123 126
- gh-sub-issues -R fohte/tasks add 123 127

分解計画は .claude/tmp/task-123-decomposition.md に保存されました。
```
