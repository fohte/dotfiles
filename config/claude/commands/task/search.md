# Search Task

Find similar or related tasks in fohte/tasks repository. This command helps locate relevant tasks for reference, linking, context understanding, or to avoid duplicates.

**Important**: All tasks are managed in Japanese language. Use Japanese for all task-related content.

## 1. Understanding similar task search

When working on a task, it's important to find:
- **Similar past tasks**: Learn from previous implementations
- **Related ongoing tasks**: Avoid conflicts and coordinate work
- **Duplicate tasks**: Prevent redundant work
- **Context from historical tasks**: Understand decisions and patterns

## 2. Search strategies

### By keywords in title and body
Search for tasks containing specific terms:

```bash
# Search for tasks mentioning specific technology or feature
gh issue list --repo fohte/tasks --search "認証" --state all
gh issue list --repo fohte/tasks --search "API" --state all

# Search for multiple keywords
gh issue list --repo fohte/tasks --search "認証 JWT" --state all
```

### By task type and area
Use labels to find similar types of tasks:

```bash
# Find all bug fixes
gh issue list --repo fohte/tasks --label "bug" --state all

# Find tasks in specific area
gh issue list --repo fohte/tasks --label "frontend" --state all
gh issue list --repo fohte/tasks --label "database" --state all

# Combine labels for precise search
gh issue list --repo fohte/tasks --label "bug,frontend" --state all
```

### By time period
Find tasks from specific time ranges:

```bash
# Recent tasks (last 30 days)
gh issue list --repo fohte/tasks --search "created:>$(date -d '30 days ago' +%Y-%m-%d)" --state all

# Tasks from specific month
gh issue list --repo fohte/tasks --search "created:2024-01-01..2024-01-31" --state all
```

## 3. Advanced similarity search

### Find tasks with similar patterns
```bash
# Tasks with similar structure (has checklist)
gh issue list --repo fohte/tasks --search "- [ ]" --state all

# Tasks with sub-tasks
gh issue list --repo fohte/tasks --search "親タスク" --state all
gh issue list --repo fohte/tasks --label "サブタスク" --state all

# Complex implementation tasks
gh issue list --repo fohte/tasks --search "実装 設計" --state all
```

### Search by solution approach
```bash
# Tasks that involved refactoring
gh issue list --repo fohte/tasks --search "リファクタリング" --state all

# Tasks with performance improvements
gh issue list --repo fohte/tasks --search "パフォーマンス 改善" --state all

# Tasks with specific technologies
gh issue list --repo fohte/tasks --search "Docker" --state all
gh issue list --repo fohte/tasks --search "GitHub Actions" --state all
```

## 4. Analyze search results

Save and analyze results for patterns:

```bash
# Save search results with context
cat > .claude/tmp/task-search-<keyword>.md << 'EOF'
# 類似タスク検索結果

検索キーワード: <keyword>
検索日: $(date)

## 見つかったパターン

### 実装アプローチ
- <パターン1>
- <パターン2>

### よくある課題
- <課題1>
- <課題2>

### 参考になるタスク
EOF

# Append formatted results
gh issue list --repo fohte/tasks --search "<keyword>" --state all --json number,title,state,labels | \
  jq -r '.[] | "- #\(.number) - \(.title) [\(.state)] (\(.labels | map(.name) | join(", ")))"' \
  >> .claude/tmp/task-search-<keyword>.md
```

## 5. Extract learnings from similar tasks

For each relevant task found, analyze:

```bash
# View specific task details
gh issue view <task-number> --repo fohte/tasks --comments

# Extract key decisions and outcomes
gh issue view <task-number> --repo fohte/tasks --json body,comments | \
  jq -r '.comments[] | select(.body | contains("決定") or contains("結果") or contains("学び"))'
```

## Best practices

- Search broadly first, then narrow down
- Look for both successful and failed approaches
- Pay attention to task completion comments for learnings
- Check closed tasks for implementation details
- Use Japanese keywords for better results
- Save useful patterns for future reference
- Consider seasonal or project-phase patterns

## Examples

### Example 1: Finding similar feature implementations
```bash
# 認証機能の実装を検索
gh issue list --repo fohte/tasks --search "認証 実装" --state all

# 結果:
# #42 - JWTベースの認証システム実装 [closed]
# #67 - OAuth2.0認証の追加 [closed]
# #89 - 二要素認証の実装 [open]
```

### Example 2: Finding related ongoing work
```bash
# 現在進行中のフロントエンド関連タスク
gh issue list --repo fohte/tasks --label "frontend" --state open

# 結果:
# #101 - UIコンポーネントのリファクタリング
# #105 - レスポンシブデザインの改善
```

### Example 3: Learning from past challenges
```bash
# パフォーマンス改善の履歴を検索
gh issue list --repo fohte/tasks --search "パフォーマンス" --state closed

# 各タスクの結果を確認
gh issue view 78 --repo fohte/tasks --comments | grep -A 5 "結果"
```

### Output example
```
「認証」に関連するタスクを検索しました。

見つかった類似タスク:
- #42: JWTベースの認証システム実装（完了）
  → トークンの有効期限設定が重要
- #67: OAuth2.0認証の追加（完了）
  → 複数プロバイダー対応の設計パターンが参考になる
- #89: 二要素認証の実装（進行中）
  → 現在作業中のため調整が必要

詳細は .claude/tmp/task-search-認証.md に保存されました。
```
