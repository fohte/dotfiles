#!/usr/bin/env bun
// PostToolUse + SessionStart(compact) hook: nudge Claude to propose splitting
// the session once context usage crosses each threshold in SPLIT_THRESHOLDS.
//
// context_window_size isn't included in hook input (only statusLine input
// has it), so statusline.ts drops it to contextWindowSizeFile() as a bridge.

import { existsSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { readTotalTokens } from './lib/transcript-usage.ts'

interface HookInput {
  hook_event_name?: string
  source?: string
  session_id?: string
  transcript_path?: string
  agent_id?: string
}

const contextWindowSizeFile = (sessionId: string) =>
  `/tmp/claude-ctx-window-size-${sessionId}`
const firedThresholdsFile = (sessionId: string) =>
  `/tmp/claude-ctx-fired-${sessionId}`

const SPLIT_THRESHOLDS = [30, 40, 50, 60, 70, 80, 90]

// Main-loop message: propose splitting to the user rather than acting
// unilaterally, since /handoff-claude only triggers on an explicit user
// request (see skills/handoff-claude/SKILL.md).
function mainSessionMessage(highest: number, percentage: number): string {
  return `Context usage has crossed ${highest}% (currently ~${Math.round(percentage)}%). Consider proposing to the user that this session be split soon:
- /delegate-claude — when the remaining work should become its own PR(s); spin up a separate Claude Code instance per PR.
- /handoff-claude — when stuck on design or investigation; first enumerate the distinct open questions/angles, then write one handoff per question if there are several (same for /delegate-claude when the remaining work splits into multiple PRs).`
}

// Subagent message: a subagent can't spawn its own follow-up subagent or
// hand off interactively, so the only move is to stop and let the parent
// re-dispatch fresh work.
function subagentMessage(highest: number, percentage: number): string {
  return `This subagent's context usage has crossed ${highest}% (currently ~${Math.round(percentage)}%). Wrap up now: report progress and findings so far as your final output, then stop. The parent session should start a fresh subagent to continue the remaining work instead of continuing this one.`
}

function handlePostToolUse(data: HookInput): void {
  if (!data.session_id || !data.transcript_path) return

  const windowSizeFile = contextWindowSizeFile(data.session_id)
  if (!existsSync(windowSizeFile)) return
  const contextWindowSize = Number(readFileSync(windowSizeFile, 'utf8').trim())
  if (!contextWindowSize) return

  const percentage =
    (readTotalTokens(data.transcript_path) / contextWindowSize) * 100

  const firedFile = firedThresholdsFile(data.session_id)
  const fired: number[] = existsSync(firedFile)
    ? JSON.parse(readFileSync(firedFile, 'utf8'))
    : []

  const newlyFired = SPLIT_THRESHOLDS.filter(
    (t) => percentage >= t && !fired.includes(t),
  )
  if (newlyFired.length === 0) return

  writeFileSync(firedFile, JSON.stringify([...fired, ...newlyFired]))

  const highest = Math.max(...newlyFired)
  const message = data.agent_id
    ? subagentMessage(highest, percentage)
    : mainSessionMessage(highest, percentage)

  console.log(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'PostToolUse',
        additionalContext: message,
      },
    }),
  )
}

function handleSessionStart(data: HookInput): void {
  // Compaction rewrites the transcript, so token counts and previously
  // fired thresholds are no longer meaningful.
  if (data.source !== 'compact' || !data.session_id) return
  const firedFile = firedThresholdsFile(data.session_id)
  if (existsSync(firedFile)) rmSync(firedFile)
}

async function main() {
  const input = await Bun.stdin.text()
  const data: HookInput = JSON.parse(input)

  if (data.hook_event_name === 'PostToolUse') {
    handlePostToolUse(data)
  } else if (data.hook_event_name === 'SessionStart') {
    handleSessionStart(data)
  }
}

main().catch(console.error)
