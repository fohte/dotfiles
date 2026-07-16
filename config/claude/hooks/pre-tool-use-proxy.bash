#!/bin/bash
# PreToolUse proxy: the single PreToolUse entry that fans out to everything
# else internally.
#
# Claude Code #15897: when settings.json registers more than one PreToolUse
# entry that matches the same tool, `updatedInput` returned by one hook is
# silently dropped. This previously caused runok's sandbox rewrite to be
# discarded whenever the Bash-matcher entry and the unscoped entry both hit
# the same Bash call. The workaround is to keep exactly one PreToolUse entry
# in settings.jsonnet and route everything through this proxy.
#
# DO NOT add another PreToolUse entry to settings.jsonnet. New per-tool guards
# belong in their own ~/.claude/hooks/<name> script, invoked from the `case`
# below. See `default-branch-edit-guard`.
input=$(cat)

# Run side-effect hook (ignore stdout, let stderr pass through)
echo "$input" | a cc hook pre-tool-use > /dev/null

tool_name=$(echo "$input" | jq -r .tool_name)

case "$tool_name" in
  Edit | Write | MultiEdit)
    exec ~/.claude/hooks/default-branch-edit-guard <<< "$input"
    ;;
  EnterWorktree)
    # EnterWorktree is "Permission Required: No" so permissions.deny does not
    # apply. Worktree creation must go through the /delegate-claude skill.
    jq -nc '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: "EnterWorktree is disabled. Use the /delegate-claude skill to spawn work in a worktree."}}'
    exit 0
    ;;
  Agent)
    exec ~/.claude/hooks/agent-guard <<< "$input"
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
