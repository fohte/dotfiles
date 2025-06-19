# Analyze Issue

Read and understand a GitHub issue to start working on it. This command fetches issue details and creates a structured context for effective task execution.

## 1. Fetch issue details

Use the `gh issue view` command to retrieve comprehensive issue information:

```bash
gh issue view <issue-number> --repo fohte/tasks --json number,title,body,labels,assignees,state,comments,createdAt,updatedAt
```

For issues in the current repository:
```bash
gh issue view <issue-number> --json number,title,body,labels,assignees,state,comments,createdAt,updatedAt
```

## 2. Extract and analyze key information

From the fetched data, identify:
- **Title and description**: Core problem or feature request
- **Labels**: Priority, type (bug/feature/task), area
- **Linked issues**: References to related issues (#123 format)
- **Checklists**: Any existing `- [ ]` items in the body
- **Comments**: Important context or updates

## 3. Create work context

Save the analyzed information to `.claude/tmp/issue-<number>-context.md`:

```markdown
# Issue #<number>: <title>

## Summary

<Brief summary of what needs to be done>

## Key Details

- Type: <bug/feature/task>
- Priority: <high/medium/low>
- Created: <date>
- Labels: <list of labels>

## Requirements

<Extracted requirements from issue body>

## Checklist Items

<Any existing checklist items>

## Related Issues

<List of linked issues with their titles>

## Important Context

<Key points from comments or description>

## Next Steps

<Suggested actions based on analysis>
```

## 4. Determine task complexity

Assess whether the issue needs:
- **Simple checklist**: For straightforward tasks with clear steps
- **Sub-issues**: For complex features requiring multiple independent tasks
- **Both**: Main checklist with some items expanded as sub-issues

## 5. Display summary and suggest next steps

After analysis, provide:
1. Brief issue overview
2. Complexity assessment
3. Suggested next command (e.g., `issue-decompose` for complex tasks)

## Best practices

- Always save context to `.claude/tmp/` for reference during work
- Include all relevant issue numbers for easy navigation
- Highlight any blockers or dependencies
- Note any special requirements or constraints mentioned
