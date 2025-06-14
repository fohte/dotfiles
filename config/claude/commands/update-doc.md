# Update or create documentation following project conventions

Update project documentation when making significant changes, discovering patterns, or solving common issues. Focus on practical, actionable information that helps future development.

# When to document

- After refactoring that changes project structure or patterns
- When discovering non-obvious constraints or gotchas
- After solving errors that others might encounter
- When establishing new conventions or workflows

# Documentation locations and purposes

## CLAUDE.md (Project root)
Project-specific instructions for Claude Code following [Anthropic's best practices](https://www.anthropic.com/engineering/claude-code-best-practices).

**Include:**
- Bash commands specific to this project
- Core file locations and purposes
- Code style and naming conventions
- Testing/validation workflows
- Repository etiquette (PR labels, commit conventions)
- Warnings about common gotchas
- Instructions to read directory READMEs

**Avoid:**
- Verbose explanations or tutorials
- Generic best practices
- Information already in README.md

**Example:**
```markdown
# Bash commands

## Build
\`\`\`bash
npm run build  # Build the project
npm test       # Run tests
\`\`\`

# Core files

- `src/`: Source code
- `config/`: Configuration files

# Code style

- Use feature-based file organization
- Name components: `<Feature>.<type>.tsx`

# Testing instructions

- Run unit tests before committing
- Integration tests require env setup

# Warnings

## Common build error
If build fails with X error, check Y first.
```

## Root README.md
Project overview, setup instructions, and general workflows.

**Include:**
- Project description and purpose
- Directory structure overview
- Setup and installation steps
- CI/CD workflows
- General contribution guidelines

# Writing guidelines

- Use bullet points or sections instead of numbered lists
- Keep descriptions concise and action-oriented
- Include code examples with clear Good/Bad patterns
- Focus on "what to do" rather than lengthy explanations
- Add warnings for non-obvious constraints
