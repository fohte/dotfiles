# Parallel agent sessions share /tmp, so a temp file rediscovered by name may
# belong to another session. Give each session its own directory to create
# temp files in. TMPDIR stays untouched because armyknife keeps state that
# other processes read (pane pause flags, PR drafts) under it.
# CODEX_THREAD_ID comes first because a Codex session launched from Claude
# Code inherits CLAUDE_CODE_SESSION_ID; Claude Code sessions override this via
# config/claude/hooks/agent-tmpdir.
_agent_session_id=${CODEX_THREAD_ID:-$CLAUDE_CODE_SESSION_ID}
if [[ -n $_agent_session_id ]]; then
  export AGENT_TMPDIR=/tmp/agent-$_agent_session_id
  [[ -d $AGENT_TMPDIR ]] || mkdir -p -m 700 "$AGENT_TMPDIR"
fi
unset _agent_session_id
