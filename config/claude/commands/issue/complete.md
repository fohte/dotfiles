# Complete Issue

Close a GitHub issue with proper documentation of outcomes, learnings, and final status. This command ensures issues are completed with comprehensive closure.

## 1. Verify completion readiness

### Check all tasks are done
```bash
# View issue to verify all checkboxes are checked
gh issue view <issue-number>

# For issues with sub-issues, verify all are closed
gh issue list --search "Part of #<issue-number>" --state open
```

### Ensure all related work is merged
```bash
# Check for open PRs referencing this issue
gh pr list --search "<issue-number>"
```

## 2. Create completion summary

Write a comprehensive closure comment:

```bash
gh issue comment <issue-number> --body "## Issue Completion Summary

### What Was Delivered
- <Main achievement 1>
- <Main achievement 2>
- <Additional deliverables>

### Implementation Details
- **Approach**: <Brief description of solution>
- **Key Changes**:
  - <File/component>: <what changed>
  - <File/component>: <what changed>
- **Related PRs**: #<pr1>, #<pr2>

### Testing & Validation
- <How the solution was tested>
- <Performance impact if any>
- <Edge cases handled>

### Outcomes & Impact
- <Business/user impact>
- <Technical improvements>
- <Performance gains>

### Learnings & Insights
- <What worked well>
- <Challenges faced and how they were resolved>
- <What could be improved next time>

### Follow-up Items
- <Any new issues created>: #<issue-number>
- <Future improvements identified>
- <Technical debt noted>

### Documentation Updates
- <Docs updated>: <link or reference>
- <README changes>: <what was added>
- <API docs>: <what was documented>

---
✅ This issue is now complete and ready to be closed.
"
```

## 3. Update final checklist status

If using checklists, ensure all items are marked complete:

```bash
# Get current body
gh issue view <issue-number> --json body -q .body > .claude/tmp/issue-final-body.md

# Verify all checkboxes are [x], then update if needed
gh issue edit <issue-number> --body-file .claude/tmp/issue-final-body.md
```

## 4. Archive work artifacts

Save important context and decisions:

```bash
# Create completion archive
mkdir -p .claude/tmp/completed-issues/
cat > .claude/tmp/completed-issues/issue-<issue-number>-complete.md << 'EOF'
# Completed: Issue #<issue-number> - <title>

Completed on: $(date)

## Summary
<Final summary of what was accomplished>

## Key Decisions
<Important technical or design decisions made>

## Code References
- Main implementation: <file:line>
- Tests: <file:line>
- Documentation: <file>

## Metrics
- Time spent: <estimated hours>
- Files changed: <count>
- Lines of code: <added/removed>

## Lessons Learned
<What to remember for future similar tasks>
EOF
```

## 5. Close the issue

### Close with final comment
```bash
# Close with reference to completion summary
gh issue close <issue-number> --comment "Issue completed successfully. See completion summary above for details.

Thank you to everyone who contributed! 🎉"
```

### Close with specific reason
```bash
# If completed as part of a PR
gh issue close <issue-number> --comment "Completed via PR #<pr-number>"

# If completed by sub-issues
gh issue close <issue-number> --comment "All sub-issues have been completed:
- #<sub1> ✅
- #<sub2> ✅
- #<sub3> ✅

Parent issue is now complete."
```

## 6. Update related tracking

### Update parent issues if this was a sub-issue
```bash
gh issue comment <parent-issue-number> --body "Sub-issue #<issue-number> has been completed.

<Brief summary of what was accomplished>

See #<issue-number> for full details."
```

### Update project boards or milestones
```bash
# Remove from active milestone if needed
gh issue edit <issue-number> --milestone ""
```

## Best practices

- Always document outcomes, not just that work is "done"
- Include specific examples and metrics where possible
- Credit contributors with @mentions
- Link to all related PRs, commits, and documentation
- Save learnings for future reference
- Create follow-up issues for any discovered work
- Be thorough but concise in summaries
- Include both technical and user-facing impacts

## Examples

### Example 1: Feature completion
```bash
gh issue comment 789 --body "## Feature Complete: User Authentication System

### Delivered
- JWT-based authentication with refresh tokens
- Login/logout endpoints with rate limiting
- Password reset flow with email verification
- Session management middleware

### Technical Impact
- Added 3 new API endpoints
- Implemented Redis for session storage
- 98% test coverage on auth module

### User Impact
- Users can now securely log in and maintain sessions
- Password reset reduces support tickets
- Session timeout improves security

### Learnings
- Redis setup was more complex than expected - documented in wiki
- Rate limiting strategy needs monitoring in production
- Consider OAuth integration for future enhancement

### Follow-up
- Created #790 for OAuth integration
- Created #791 for admin user management

This completes the authentication milestone! 🚀"

gh issue close 789
```

### Example 2: Bug fix completion
```bash
gh issue comment 456 --body "## Bug Fixed: Data Export Memory Leak

### Root Cause
Memory leak was caused by unclosed file streams in the CSV export module.

### Solution
- Implemented proper stream cleanup in finally blocks
- Added memory monitoring for large exports
- Set maximum chunk size for streaming

### Validation
- Memory usage stays constant even with 1M+ row exports
- Added integration test to prevent regression
- Monitored in staging for 48 hours

### Impact
- Resolves customer complaints about export failures
- Reduces server memory usage by ~60% during exports
- Enables larger data exports

Fixes deployed to production in v2.3.4."

gh issue close 456 --comment "Bug fixed and deployed. Monitoring shows stable memory usage."
```
