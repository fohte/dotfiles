# Update Issue

Update GitHub issue status, progress, and documentation. This command handles progress tracking, comment updates, and checklist maintenance.

## 1. Update issue progress

### Add a progress comment

Document work progress with detailed comments:

```bash
gh issue comment <issue-number> --body "## Progress Update

### Completed
- <What has been done>
- <Specific achievements>

### In Progress
- <Current work>

### Next Steps
- <What's planned next>

### Blockers (if any)
- <Any issues encountered>
"
```

### Quick status update

For brief updates:
```bash
gh issue comment <issue-number> --body "Status: <brief status update>"
```

## 2. Update checklists in issue body

### Get current issue body
```bash
# Save current body to edit
gh issue view <issue-number> --json body -q .body > .claude/tmp/issue-body.md
```

### Update checklist items
Edit the saved body to mark completed items:
```markdown
## Tasks
- [x] Research existing implementation ✓ Done
- [x] Design the solution ✓ Done
- [ ] Implement core functionality ← Currently working on this
- [ ] Add tests
- [ ] Update documentation
```

### Apply the update
```bash
gh issue edit <issue-number> --body-file .claude/tmp/issue-body.md
```

## 3. Add or update todo lists

### Add new todo section
```bash
# Append new todos to existing body
gh issue view <issue-number> --json body -q .body > .claude/tmp/issue-body.md
cat >> .claude/tmp/issue-body.md << 'EOF'

## Additional Tasks Discovered
- [ ] Refactor authentication module
- [ ] Add rate limiting
- [ ] Update API documentation
EOF

gh issue edit <issue-number> --body-file .claude/tmp/issue-body.md
```

### Convert findings to actionable items
When discovering new requirements during work:
```bash
gh issue comment <issue-number> --body "## New Requirements Identified

While working on this issue, I discovered the following additional tasks:

1. **Task**: <description>
   - Why: <reason this is needed>
   - Impact: <what it affects>

2. **Task**: <description>
   - Why: <reason>
   - Impact: <consequences>

Should these be added to the current issue or created as separate issues?"
```

## 4. Update labels and metadata

### Update labels based on progress
```bash
# Add/remove labels
gh issue edit <issue-number> --add-label "in-progress"
gh issue edit <issue-number> --remove-label "ready"

# Update priority
gh issue edit <issue-number> --remove-label "priority:low" --add-label "priority:high"
```

### Assign or reassign
```bash
gh issue edit <issue-number> --add-assignee @me
gh issue edit <issue-number> --add-assignee username
```

## 5. Link related work

### Reference commits and PRs
```bash
gh issue comment <issue-number> --body "Related work:
- Commit: <sha> - <description>
- PR: #<pr-number> - <title>
- Related issue: #<issue-number> - <context>
"
```

### Update sub-issue progress
For parent issues with sub-issues:
```bash
gh issue comment <issue-number> --body "## Sub-issue Progress

- #124 - ✅ Completed: JWT token generation
- #125 - 🔄 In Progress: Login/logout endpoints (80% done)
- #126 - ⏳ Pending: Authentication middleware
- #127 - ⏳ Blocked: Waiting for backend completion

Overall Progress: 2/4 sub-issues completed (50%)
"
```

## 6. Document decisions and changes

### Technical decisions
```bash
gh issue comment <issue-number> --body "## Technical Decision

### Context
<What prompted this decision>

### Options Considered
1. <Option 1>: <pros/cons>
2. <Option 2>: <pros/cons>

### Decision
<What was chosen and why>

### Impact
<How this affects the implementation>
"
```

### Scope changes
```bash
gh issue comment <issue-number> --body "## Scope Update

### Original Scope
<What was initially planned>

### Changed To
<New scope>

### Reason
<Why the change is needed>

### Impact on Timeline
<How this affects completion>
"
```

## Best practices

- Update regularly but avoid noise - batch small updates
- Be specific about progress percentages and blockers
- Keep checklists in issue body, detailed updates in comments
- Use emoji sparingly for status: ✅ ❌ 🔄 ⏳ 🚧
- Link to relevant commits, PRs, and related issues
- Document decisions that affect future work
- Update labels to reflect current state
- Notify stakeholders of significant changes with @mentions

## Examples

### Example 1: Daily progress update
```bash
gh issue comment 123 --body "## Daily Update - $(date +%Y-%m-%d)

### Completed Today
- Implemented user authentication endpoint
- Added input validation
- Created unit tests for auth module

### Tomorrow's Plan
- Integration tests
- Error handling improvements
- Documentation update

No blockers currently."
```

### Example 2: Updating complex checklist
```bash
# First get the current body
gh issue view 456 --json body -q .body > .claude/tmp/issue-456-body.md

# Edit to update progress
# Then apply update
gh issue edit 456 --body-file .claude/tmp/issue-456-body.md

# Add progress comment
gh issue comment 456 --body "Updated checklist: 5/8 tasks completed (62.5%). Currently working on API integration."
```
