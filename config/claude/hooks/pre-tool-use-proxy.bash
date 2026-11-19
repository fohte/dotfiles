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

# Keep the one-time retry approval for arbitration with this tool's guards.
armyknife_output=$(echo "$input" | a agent hook pre-tool-use)
armyknife_status=$?
armyknife_allowed=false
if [ "$armyknife_status" -eq 0 ] && jq -es '
  length == 1
  and (.[0] | type == "object")
  and (.[0].hookSpecificOutput | type == "object")
  and .[0].hookSpecificOutput.hookEventName == "PreToolUse"
  and .[0].hookSpecificOutput.permissionDecision == "allow"
' <<< "$armyknife_output" > /dev/null 2>&1; then
  armyknife_allowed=true
fi

run_guard() {
  local guard_output guard_status

  if [ "$armyknife_allowed" != true ]; then
    "$@" <<< "$input"
    return $?
  fi

  guard_output=$("$@" <<< "$input")
  guard_status=$?
  printf '%s' "$guard_output" | ~/.claude/hooks/pre-tool-use-retry-approval "$armyknife_output" "$guard_status"
}

tool_name=$(echo "$input" | jq -r .tool_name)

case "$tool_name" in
  Edit | Write | MultiEdit)
    deny=$(~/.claude/hooks/ponytail-comment-guard <<< "$input")
    deny_status=$?
    if [ -n "$deny" ]; then
      if [ "$armyknife_allowed" = true ]; then
        printf '%s' "$deny" | ~/.claude/hooks/pre-tool-use-retry-approval "$armyknife_output" "$deny_status"
      else
        echo "$deny"
      fi
      exit 0
    fi
    run_guard ~/.claude/hooks/default-branch-edit-guard
    exit $?
    ;;
  EnterWorktree)
    # EnterWorktree is "Permission Required: No" so permissions.deny does not
    # apply. Other sessions must use the /delegate skill.
    agent_id=$(echo "$input" | jq -r '.agent_id // empty')
    if [ -z "$agent_id" ]; then
      session_id=$(echo "$input" | jq -r '.session_id // empty')
      if [ -n "$session_id" ]; then
        peers_json=$(a agent peer list) || peers_json=
        if [ -n "$peers_json" ] && echo "$peers_json" | jq -e --arg session_id "$session_id" \
          'any(.[]; .session_id == $session_id and .work_type == "designer")' > /dev/null; then
          if [ "$armyknife_allowed" = true ]; then
            printf '' | ~/.claude/hooks/pre-tool-use-retry-approval "$armyknife_output" 0
          fi
          exit 0
        fi
      fi
    fi
    guard_output=$(jq -nc '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: "EnterWorktree is disabled. Use the delegate skill to spawn work in a worktree."}}')
    if [ "$armyknife_allowed" = true ]; then
      printf '%s' "$guard_output" | ~/.claude/hooks/pre-tool-use-retry-approval "$armyknife_output" 0
    else
      printf '%s\n' "$guard_output"
    fi
    exit 0
    ;;
  TaskStop)
    run_guard ~/.claude/hooks/task-stop-guard
    exit $?
    ;;
  Agent)
    run_guard ~/.claude/hooks/agent-guard
    exit $?
    ;;
  AskUserQuestion)
    run_guard ~/.claude/hooks/ask-user-question-guard
    exit $?
    ;;
  # The generic executor bypasses catalog permissions; keep Seer's deny here
  # and let auto mode classify all other calls.
  mcp__sentry__execute_sentry_tool)
    run_guard ~/.claude/hooks/sentry-seer-guard
    exit $?
    ;;
  Skill)
    # Only subagent-invoked calls need the guard; main-thread Skill calls
    # fall through to the no-op exit below without spawning it.
    agent_id=$(echo "$input" | jq -r '.agent_id // empty')
    if [ -n "$agent_id" ]; then
      run_guard ~/.claude/hooks/skill-subagent-guard
      exit $?
    fi
    ;;
esac

if [ "$tool_name" != "Bash" ]; then
  if [ "$armyknife_allowed" = true ]; then
    printf '' | ~/.claude/hooks/pre-tool-use-retry-approval "$armyknife_output" 0
  fi
  exit 0
fi

# Runs in a command substitution below, so each `exit` only ends the branch and
# its output still flows to bash-bg-timeout-default.
bash_permission() {
  # runok hook emits a hookSpecificOutput JSON with permissionDecision
  # (allow|ask|deny) for a matched rule, and may also include updatedInput
  # when runok rewrites the command. `pass` (no rule matched, deferred to
  # Claude Code's own permission handling) produces empty stdout instead.
  runok_output=$(echo "$input" | runok hook --agent claude-code)

  # Empty/non-JSON stdout is indistinguishable between `pass` and runok crashing
  # or returning garbage; both fall through with no hook output (Claude Code
  # treats empty stdout as "no decision"). Without this check, the next jq call
  # would coerce missing fields into "allow" and silently bypass runok on a crash.
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

  # Unlike `rtk rewrite`, this reads cwd and leaves git unwrapped in .claude/worktrees/.
  rewritten=$(echo "$input" | jq -c --argjson t "$base_input" '.tool_input = $t' |
    rtk hook claude 2> /dev/null | jq -r '.hookSpecificOutput.updatedInput.command // empty' 2> /dev/null || true)
  if [ -z "$rewritten" ] || [ "$rewritten" = "$cmd" ]; then
    echo "$runok_output"
    exit 0
  fi

  updated_input=$(echo "$base_input" | jq -c --arg c "$rewritten" '.command = $c')
  echo "$runok_output" | jq -c --argjson u "$updated_input" '.hookSpecificOutput.updatedInput = $u'
}

output=$(bash_permission)
output=$(~/.claude/hooks/bash-bg-timeout-default "$output" <<< "$input")

if [ "$armyknife_allowed" = true ]; then
  output=$(printf '%s' "$output" | ~/.claude/hooks/pre-tool-use-retry-approval "$armyknife_output" 0)
fi

if [ -n "$output" ] && [ "$output" != "null" ]; then
  printf '%s\n' "$output"
fi
