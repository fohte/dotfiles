# Complete Task

Close a task in fohte/tasks repository.

**Important**: All tasks are managed in Japanese language. Use Japanese for all task-related content.

## 1. Add PR links if any

If you implemented code, add PR links as a comment:

```bash
gh issue comment <task-number> --repo fohte/tasks --body "- <pr-url>
- <pr-url>"
```

## 2. Close the task

Use the appropriate reason:

```bash
# For completed tasks
gh issue close <task-number> --repo fohte/tasks --reason completed --comment "完了したので close"

# For tasks that won't be done
gh issue close <task-number> --repo fohte/tasks --reason "not planned" --comment "対応不要になったので close"
```

## Best practices

- Document PR links before closing
- Use clear reason (completed or not planned)
- Keep closure comment simple and direct

## Example

```bash
# Add PR link
gh issue comment 123 --repo fohte/tasks --body "- https://github.com/fohte/someproject/pull/45"

# Close as completed
gh issue close 123 --repo fohte/tasks --reason completed --comment "完了したので close"
```
