# Decompose Issue

Break down a GitHub issue into manageable subtasks. This command helps structure work by creating either simple checklists or separate sub-issues based on complexity.

## 1. Analyze issue complexity

First, run `issue-analyze` if you haven't already, then assess:
- Number of distinct features or components involved
- Dependencies between tasks
- Estimated effort for each part
- Whether tasks can be done in parallel

## 2. Choose decomposition strategy

### For simple tasks (use checklist)
When tasks are:
- Small and sequential
- All part of a single coherent change
- Can be completed in one work session

Update the issue body with a checklist:
```bash
gh issue edit <issue-number> --body "$(cat <<'EOF'
<existing body>

## Tasks
- [ ] Research existing implementation
- [ ] Design the solution
- [ ] Implement core functionality
- [ ] Add tests
- [ ] Update documentation
EOF
)"
```

### For complex tasks (use sub-issues)
When tasks are:
- Large and independent
- Require different expertise
- Can be worked on in parallel
- Need separate tracking

## 3. Create sub-issues for complex tasks

For each major component, create a sub-issue:

```bash
gh issue create \
  --title "[Parent #<parent-number>] <Subtask title>" \
  --body "Part of #<parent-number>

## Context
<Brief context from parent issue>

## Task
<Specific task description>

## Acceptance Criteria
<What defines completion>
" \
  --label "sub-issue" \
  --repo fohte/tasks
```

## 4. Link sub-issues to parent

Update the parent issue to reference all sub-issues:

```bash
gh issue comment <parent-number> --body "## Sub-issues created:
- #<sub-issue-1> - <title>
- #<sub-issue-2> - <title>
- #<sub-issue-3> - <title>

Track progress through these linked issues."
```

## 5. Create tracking structure

Save the decomposition plan to `.claude/tmp/issue-<number>-decomposition.md`:

```markdown
# Decomposition: Issue #<number>

## Strategy: <checklist|sub-issues|mixed>

## Task Breakdown

### Task 1: <Name>
- Description: <what needs to be done>
- Type: <checklist-item|sub-issue>
- Issue: <#number if sub-issue>
- Dependencies: <none|list>
- Estimated effort: <small|medium|large>

### Task 2: <Name>
...

## Execution Order
1. <Task that should be done first>
2. <Next task>
...

## Notes
<Any special considerations>
```

## Best practices

- Keep subtask titles descriptive but concise
- Include parent issue number in sub-issue titles for context
- Use labels consistently (e.g., "sub-issue", priority labels)
- Don't over-decompose - aim for 3-7 subtasks
- Consider dependencies when ordering tasks
- Update parent issue when sub-issues are completed

## Examples

### Simple checklist example
```markdown
## Implementation tasks
- [ ] Add new API endpoint
- [ ] Update frontend to call new endpoint
- [ ] Add error handling
- [ ] Write unit tests
```

### Sub-issues example
```
Parent: #123 - Add user authentication system

Sub-issues:
- #124 - [Parent #123] Implement JWT token generation
- #125 - [Parent #123] Create login/logout endpoints
- #126 - [Parent #123] Add authentication middleware
- #127 - [Parent #123] Update frontend auth flow
```
