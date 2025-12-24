# Create or update todo list

Create and maintain a structured todo list for tracking task progress. The todo list helps break down complex tasks into actionable items and track completion status.

## Todo file location

Todo lists must store at `.z/todo.md`. `~/.z/` is gitignored, so no commits are needed.

## Creating the todo list

- Create a new file if it doesn't exist, otherwise update the existing one
- Break down tasks into concrete, actionable items
- Use nested todos for hierarchical task organization when appropriate (don't force parent-child relationships)
- Use GitHub Flavored Markdown task list syntax: `- [ ]` for incomplete, `- [x]` for complete

## Todo list structure

```markdown
# Todo List

## Main Feature

- [ ] Research existing implementation patterns
- [ ] Design the architecture
    - [ ] Define data models
    - [ ] Plan API endpoints
- [ ] Implement core functionality
- [ ] Add tests
- [ ] Update documentation

## Bug Fixes

- [ ] Fix validation error in user input
- [ ] Handle edge case for empty responses
```

## Working with the todo list

- Reference this todo list when executing tasks
- Mark items as complete (`- [x]`) as you finish them
- Add new subtasks if you discover additional work needed
- Keep the list updated throughout the work session

## Best practices

- Write clear, specific task descriptions
- Group related tasks under descriptive headers
- Start with high-level tasks, then break down into subtasks as needed
- Include enough context in each item to understand what needs to be done
