# Complete Task

Close a task in fohte/tasks repository.

**Important**: All tasks are managed in Japanese language. Use Japanese for all task-related content.

## 1. Add PR links if any

If you implemented code, add PR links as a comment:

```bash
task comment <task-number> --body "- <pr-url>
- <pr-url>"
```

## 2. Close the task

Use the appropriate reason:

```bash
# For completed tasks (default)
task close <task-number>

# For completed tasks with custom comment
task close <task-number> --comment "完了したので close"

# For tasks that won't be done
task close <task-number> --reason "not planned"

# For tasks that won't be done with custom comment
task close <task-number> --reason "not planned" --comment "対応不要になったので close"
```

## Best practices

- Document PR links before closing
- Use clear reason (completed or not planned)
- Keep closure comment simple and direct

## Example

```bash
# Add PR link
task comment 123 --body "- https://github.com/fohte/someproject/pull/45"

# Close as completed
task close 123
```
