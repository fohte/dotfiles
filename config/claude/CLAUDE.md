# Pull requests

- Format: ## Why (purpose/background) + ## What (changes in present tense)
- After push: `gh run watch $(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')`

# Code style

- Comments: English only, explain "why" not "what"
