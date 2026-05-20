#!/bin/bash
# PreToolUse dispatcher.
#
# This file is a DISPATCHER, not a place to add new hook logic.
# Claude Code #15897 silently drops `updatedInput` when multiple hooks match
# the same tool, so all PreToolUse work must funnel through one entry point.
# The job of this script is limited to:
#   1. Forward stdin to side-effect hooks (`a cc hook pre-tool-use`).
#   2. `exec` a per-tool handler script for tools that need their own logic.
#   3. Run the Bash-specific pipeline (runok check → rtk rewrite).
#
# DO NOT add new judgment logic here. To add a new PreToolUse guard:
#   - Create a standalone script under ~/.claude/hooks/<name>
#   - Add a `case` branch below that `exec`s it
# See `cbm-code-discovery-gate` for an example.
input=$(cat)

# Run side-effect hook (ignore stdout, let stderr pass through)
echo "$input" | a cc hook pre-tool-use > /dev/null

tool_name=$(echo "$input" | jq -r .tool_name)

# codebase-memory-mcp code-discovery gate: block the first Grep/Glob/Read in a
# session and nudge the agent toward the knowledge graph. Subsequent calls
# pass through (gate file in /tmp keyed on PPID).
case "$tool_name" in
  Grep | Glob | Read | Search)
    exec ~/.claude/hooks/cbm-code-discovery-gate
    ;;
esac

if [ "$tool_name" != "Bash" ]; then
  exit 0
fi

# runok check always emits a hookSpecificOutput JSON with permissionDecision (allow|ask|deny),
# and may also include updatedInput when runok rewrites the command.
runok_output=$(echo "$input" | runok check --input-format claude-code-hook)

# Fail-closed-ish guard: if runok crashed or returned non-JSON, fall through with no
# hook output (Claude Code treats empty stdout as "no decision"). Without this, the
# next jq call would coerce missing fields into "allow" and silently bypass runok.
if [ -z "$runok_output" ] || ! echo "$runok_output" | jq -e . > /dev/null 2>&1; then
  exit 0
fi

decision=$(echo "$runok_output" | jq -r '.hookSpecificOutput.permissionDecision // "allow"')

# ask: defer to the user; do not rewrite (the approval prompt and the executed command
# must match). deny: rewrite is meaningless. Only allow flows through to rtk.
if [ "$decision" != "allow" ] || ! command -v rtk > /dev/null 2>&1; then
  echo "$runok_output"
  exit 0
fi

# Use runok's updatedInput as the base if present, else fall back to original tool_input.
base_input=$(echo "$runok_output" | jq -c '.hookSpecificOutput.updatedInput // empty')
if [ -z "$base_input" ]; then
  base_input=$(echo "$input" | jq -c '.tool_input')
fi

cmd=$(echo "$base_input" | jq -r '.command // empty')
if [ -z "$cmd" ]; then
  echo "$runok_output"
  exit 0
fi

# Skip multi-line commands (heredocs, embedded newlines): rtk rewrite tokenizes
# without re-quoting, so reshaping such commands risks changing semantics.
case "$cmd" in
  *$'\n'*)
    echo "$runok_output"
    exit 0
    ;;
esac

# rtk rewrite's exit code is unstable across versions; rely on stdout content only.
rewritten=$(rtk rewrite "$cmd" 2> /dev/null || true)
if [ -z "$rewritten" ] || [ "$rewritten" = "$cmd" ]; then
  echo "$runok_output"
  exit 0
fi

updated_input=$(echo "$base_input" | jq -c --arg c "$rewritten" '.command = $c')
echo "$runok_output" | jq -c --argjson u "$updated_input" '.hookSpecificOutput.updatedInput = $u'
