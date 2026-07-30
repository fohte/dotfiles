#!/usr/bin/env bun
// PostToolUse + SessionStart(compact) hook: force Claude to state a 分割/継続
// verdict once context usage crosses each threshold in SPLIT_THRESHOLDS.
//
// context_window_size isn't included in hook input (only statusLine input
// has it), so statusline.ts drops it to contextWindowSizeFile() as a bridge.

import { existsSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { AUTO_COMPACT_RATIO, readTotalTokens } from './lib/transcript-usage.ts'

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

// Demand a stated verdict rather than the split itself: /handoff-claude only
// triggers on an explicit user request (see skills/handoff-claude/SKILL.md),
// so the user has to be given something to overrule.
function mainSessionMessage(percentage: number): string {
  const p = Math.round(percentage)
  return `Context usage is at ~${p}%.

Context is a cost, not a budget: every additional token degrades reasoning quality and is re-billed on every subsequent turn. Having room left is NOT a reason to keep going. The default is to split; continuing is what needs justification.

Decide now, and state the verdict as the last line of your next message:

  ⚠ context ~${p}% — 分割: <残作業をどう切り出すか 1 行>
  ⚠ context ~${p}% — 継続: <残作業がこのセッションの蓄積文脈を必要とする理由 1 行>

"継続" is allowed only when the remaining work genuinely depends on context a fresh session would lack. "まだ余裕がある" and "引き継ぎが面倒" do not qualify: the handoff cost must be weighed against the ongoing cost of carrying this context, not against zero.

Deciding silently is never allowed, since the user cannot overrule a judgment they never saw. One line does not interrupt your work, so being mid-workflow is not a reason to defer it.

When the verdict is 分割: /delegate-claude when the remaining work should become its own PR(s), /handoff-claude when stuck on design or investigation. Enumerate the distinct open questions/PRs first, and write one handoff per question if there are several.`
}

// Subagent message: a subagent can't spawn its own follow-up subagent or
// hand off interactively, so the only move is to stop and let the parent
// re-dispatch fresh work.
function subagentMessage(percentage: number): string {
  return `This subagent's context usage is at ~${Math.round(percentage)}%. Wrap up now: report progress and findings so far as your final output, then stop. The parent session should start a fresh subagent to continue the remaining work instead of continuing this one.`
}

function handlePostToolUse(data: HookInput): void {
  if (!data.session_id || !data.transcript_path) return

  const windowSizeFile = contextWindowSizeFile(data.session_id)
  if (!existsSync(windowSizeFile)) return
  const contextWindowSize = Number(readFileSync(windowSizeFile, 'utf8').trim())
  if (!contextWindowSize) return

  // Same basis as statusline.ts's displayed percentage: usage relative to
  // the auto-compact threshold, not the raw window size.
  const percentage =
    (readTotalTokens(data.transcript_path) /
      (contextWindowSize * AUTO_COMPACT_RATIO)) *
    100

  const firedFile = firedThresholdsFile(data.session_id)
  const fired: number[] = existsSync(firedFile)
    ? JSON.parse(readFileSync(firedFile, 'utf8'))
    : []

  const newlyFired = SPLIT_THRESHOLDS.filter(
    (t) => percentage >= t && !fired.includes(t),
  )
  if (newlyFired.length === 0) return

  writeFileSync(firedFile, JSON.stringify([...fired, ...newlyFired]))

  const message = data.agent_id
    ? subagentMessage(percentage)
    : mainSessionMessage(percentage)

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
