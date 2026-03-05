#!/bin/bash
# Combined PreToolUse hook for all tools.
# Bundles a cc hook and runok into a single hook to avoid Claude Code #15897
# (updatedInput silently dropped when multiple hooks match the same tool).
input=$(cat)

# Run side-effect hook (ignore stdout, let stderr pass through)
echo "$input" | a cc hook pre-tool-use > /dev/null

# Run runok check only for Bash tool (its stdout is the hook response)
tool_name=$(echo "$input" | jq -r .tool_name)
if [ "$tool_name" = "Bash" ]; then
  echo "$input" | runok check --input-format claude-code-hook
fi
