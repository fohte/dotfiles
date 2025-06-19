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
- **Checklists**: Any existing `- [ ]` items in the body
- **Comments**: Important context, decisions, or updates

## 3. Create work context

Save the analyzed information to `.claude/tmp/task-<number>-context.md`:

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

## チェックリスト

<既存のチェックリスト項目>

## 関連タスク

<リンクされているタスクとその概要>

## 重要なコンテキスト

<コメントや説明から抽出した重要なポイント>

## 次のステップ

<このタスクをどう進めるかの提案>
```

## 4. Determine task complexity

Assess whether the task needs:
- **Simple checklist**: For straightforward tasks with clear steps
- **Sub-tasks**: For complex work requiring multiple independent tasks
- **Both**: Main checklist with some items expanded as sub-tasks

## 5. Display summary and suggest next steps

After analysis, provide:
1. Brief task overview (in Japanese)
2. Complexity assessment
3. Suggested next command (e.g., `task-decompose` for complex tasks)

## Best practices

- Always save context to `.claude/tmp/` for reference during work
- Include all relevant task numbers for easy navigation
- Highlight any blockers or dependencies
- Note any special requirements or constraints mentioned
- Write all task-related content in Japanese
- Use clear and concise Japanese for better understanding

## Example output

```
タスク #42 を分析しました: 「ユーザー認証システムの実装」

複雑度: 高（複数の独立したコンポーネントが必要）

次の推奨アクション:
- task-decompose を使用してサブタスクに分解
- 認証フロー、データベース設計、APIエンドポイントなどに分割することを推奨

コンテキストは .claude/tmp/task-42-context.md に保存されました。
```
