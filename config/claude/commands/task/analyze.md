# Analyze Task

Read and understand a task from fohte/tasks repository to start working on it. This command fetches task details and creates a structured context for effective execution.

**Important**: All tasks are managed in Japanese language. Use Japanese for all task-related content.

## 1. Fetch task details

Retrieve comprehensive task information from fohte/tasks repository:

```bash
gh issue view <task-number> --repo fohte/tasks --json number,title,body,labels,assignees,state,comments,createdAt,updatedAt
```

## 2. Extract and analyze key information

From the fetched data, identify:
- **Title and description**: What needs to be done
- **Labels**: Priority, type, area, project
- **Linked tasks**: References to related tasks (#123 format)
- **TODOs**: Any existing `- [ ]` items in the body
- **Comments**: Important context, decisions, or updates

## 3. Search for related tasks

Find similar or related tasks to understand context and avoid duplication:

### Search by keywords from the task
```bash
# Extract key terms from title and search for similar tasks
gh issue list --repo fohte/tasks --search "<extracted-keywords>" --state all
```

### Search by labels
```bash
# Find tasks with same labels to understand patterns
gh issue list --repo fohte/tasks --label "<label1>,<label2>" --state all
```

### Analyze search results
- Identify similar completed tasks for reference
- Find ongoing related work to coordinate
- Learn from past implementations and challenges
- Extract useful patterns and approaches

## 4. Create work context

Save the analyzed information including related tasks to `.claude/tmp/task-<number>-context.md`:

```markdown
# Task #<number>: <title>

## サマリー

<タスクの概要を日本語で記載>

## 詳細情報

- タイプ: <バグ修正/機能追加/改善/調査>
- 優先度: <高/中/低>
- 作成日: <date>
- ラベル: <list of labels>

## 要件

<タスクの要件を日本語で整理>

## TODOs

<既存のTODOリスト項目>

## 関連タスク

### 直接リンクされているタスク
<リンクされているタスクとその概要>

### 類似・関連タスク（検索結果）
<検索で見つかった関連タスクとその学び>

## 重要なコンテキスト

<コメントや説明から抽出した重要なポイント>

## 次のステップ

<このタスクをどう進めるかの提案>
```

## 5. Determine task complexity

Assess whether the task needs:
- **Simple TODOs**: For straightforward tasks with clear steps
- **Sub-tasks**: For complex work requiring multiple independent tasks
- **Both**: Main TODOs with some items expanded as sub-tasks

## 6. Display summary and next steps

After analysis, provide:
1. Brief task overview (in Japanese)
2. Complexity assessment
3. If the task is complex and needs decomposition, automatically run `~/.claude/commands/task/decompose.md`
4. Otherwise, suggest appropriate next steps

## Best practices

- Always save context to `.claude/tmp/` for reference during work
- Include all relevant task numbers for easy navigation
- Highlight any blockers or dependencies
- Note any special requirements or constraints mentioned
- Write all task-related content in Japanese
- Use clear and concise Japanese for better understanding
- Search for related tasks to avoid duplication and learn from past work
- Consider patterns from similar completed tasks

## Example outputs

### For complex tasks (auto-decompose)
```
タスク #42 を分析しました: 「ユーザー認証システムの実装」

複雑度: 高（複数の独立したコンポーネントが必要）

コンテキストは .claude/tmp/task-42-context.md に保存されました。

自動的にタスクを分解します...
[~/.claude/commands/task/decompose.md を実行]
```

### For simple tasks
```
タスク #43 を分析しました: 「READMEファイルの誤字修正」

複雑度: 低（単純な修正タスク）

次の推奨アクション:
- 直接修正を実施
- PR作成後、~/.claude/commands/task/complete.md で完了

コンテキストは .claude/tmp/task-43-context.md に保存されました。
```
