# Search Issues

Find existing GitHub issues using various search criteria. This command helps locate relevant issues for reference, linking, or to avoid duplicates.

## 1. Basic search

Use `gh issue list` with search parameters:

```bash
# Search by title/body content
gh issue list --search "keyword" --repo fohte/tasks

# Search in current repository
gh issue list --search "keyword"
```

## 2. Advanced search filters

Combine multiple criteria for precise results:

```bash
# By state
gh issue list --state open    # or closed, all
gh issue list --state all --search "authentication"

# By labels
gh issue list --label "bug,priority:high"
gh issue list --label "sub-issue" --search "parent #123"

# By assignee
gh issue list --assignee @me
gh issue list --assignee fohte

# By author
gh issue list --author @me

# By date
gh issue list --search "created:>2024-01-01"
gh issue list --search "updated:2024-01-01..2024-01-31"

# Combined filters
gh issue list --state open --label "feature" --assignee @me --search "API"
```

## 3. Search related issues

Find issues linked to a specific issue:

```bash
# Find sub-issues of a parent
gh issue list --search "Part of #123" --repo fohte/tasks
gh issue list --search "[Parent #123]" --repo fohte/tasks

# Find issues mentioning a specific issue
gh issue list --search "#123" --repo fohte/tasks
```

## 4. Format and save results

### Display options

```bash
# Limit number of results
gh issue list --limit 20 --search "keyword"

# Show specific fields
gh issue list --json number,title,labels,state --search "keyword"

# Custom format with jq
gh issue list --json number,title,labels,state --search "keyword" | \
  jq -r '.[] | "#\(.number) - \(.title) [\(.labels | map(.name) | join(", "))]"'
```

### Save search results

Save results to `.claude/tmp/issue-search-results.md`:

```bash
# Create formatted results file
cat > .claude/tmp/issue-search-results.md << 'EOF'
# Issue Search Results

Search query: <your search>
Date: $(date)
Repository: fohte/tasks

## Results

EOF

# Append formatted results
gh issue list --search "<query>" --json number,title,state,labels,createdAt | \
  jq -r '.[] | "### #\(.number) - \(.title)\n- State: \(.state)\n- Labels: \(.labels | map(.name) | join(", "))\n- Created: \(.createdAt)\n"' \
  >> .claude/tmp/issue-search-results.md
```

## 5. Search patterns for common scenarios

### Find all open tasks for current sprint
```bash
gh issue list --state open --label "sprint:current" --assignee @me
```

### Find bugs without assignee
```bash
gh issue list --state open --label "bug" --assignee ""
```

### Find stale issues (no activity in 30 days)
```bash
gh issue list --state open --search "updated:<$(date -d '30 days ago' +%Y-%m-%d)"
```

### Find issues with checklists
```bash
gh issue list --search "- [ ]" --state open
```

### Find completed sub-issues
```bash
gh issue list --state closed --label "sub-issue" --search "Part of #"
```

## Best practices

- Use specific search terms to reduce noise
- Combine multiple filters for precision
- Save complex searches as shell aliases or scripts
- Include repository flag when searching across multiple repos
- Check both open and closed issues to avoid duplicates
- Use JSON output with jq for custom formatting

## Examples

### Example 1: Find all authentication-related issues
```bash
gh issue list --search "auth OR authentication OR login" --state all --repo fohte/tasks
```

### Example 2: Find sub-issues of #123 that are still open
```bash
gh issue list --state open --search "[Parent #123]" --repo fohte/tasks
```

### Example 3: Find high-priority bugs assigned to you
```bash
gh issue list --state open --label "bug,priority:high" --assignee @me --repo fohte/tasks
```
