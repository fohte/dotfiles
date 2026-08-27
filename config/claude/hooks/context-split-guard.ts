#!/usr/bin/env bun
// PostToolUse + SessionStart(compact) hook: force Claude to enumerate the
// remaining tasks and state how it will run them (subagents / delegate /
// handoff / 継続) once context usage crosses each SPLIT_THRESHOLDS entry.
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

// Fires from 20% because "あと少しで終わるから" stays available as an excuse at
// any single threshold; the low ones exist to catch a session that is burning
// context faster than the work justifies.
const SPLIT_THRESHOLDS = [20, 25, 30, 40, 50, 60, 70, 80, 90]

// Demand a stated verdict rather than the action itself: /delegate-claude and
// /handoff-claude only trigger on an explicit user request (see their
// SKILL.md), and a silent choice to keep working inline leaves the user
// nothing to overrule.
function mainSessionMessage(percentage: number): string {
  const p = Math.round(percentage)
  return `Context usage is at ~${p}%.

Context is a cost, not a budget: every additional token degrades reasoning quality and is re-billed on every subsequent turn. Having room left is NOT a reason to keep going.

Burning context this fast usually means the work is being run the wrong way: done inline in this session instead of dispatched. So do both of these in your next message, before resuming work:

1. List the remaining work as concrete tasks, one line each.
2. Decide how those tasks should be run, and state the verdict as the last line:

  ⚠ context ~${p}% — subagents: <どのタスクをどの観点に割って何個の subagent に投げるか>
  ⚠ context ~${p}% — delegate: <どう PR 単位に切り出すか>
  ⚠ context ~${p}% — handoff: <何を引き継ぐか>
  ⚠ context ~${p}% — 継続: <残タスクがこのセッションの蓄積文脈を必要とする理由>

- subagents: the default for any self-contained task (investigation, search, review, mechanical edits). A subagent's working context never enters this session, only its summary does, so dispatching is strictly cheaper than doing it inline.
  Go task by task and ask what part of it can be carved out. A single investigation normally becomes several subagents, one per angle (this file's callers / how the upstream tool behaves / what the existing tests cover), dispatched in parallel — splitting by angle is what makes the work parallel and each report small, so it is the normal case, not an optimization.
  What stays here is the part that cannot be carved out: choosing the angles, merging what comes back, and the judgment and edits that need the merged picture. Handing the remaining work to one subagent as a block is the opposite of this verdict — it re-runs the same monolithic session elsewhere, and you get one summary you cannot steer or audit.
- delegate (/delegate-claude): the remaining work should become its own PR(s).
- handoff (/handoff-claude): stuck on design or investigation, and this session should be restarted fresh.
- 継続: the remaining tasks genuinely depend on context a subagent or a fresh session would lack.

"あと少しで終わる" is not a verdict: enumerate the tasks first, and let the list show it. "まだ余裕がある" and "引き継ぎが面倒" do not qualify either, since the handoff cost must be weighed against the ongoing cost of carrying this context, not against zero.

Deciding silently is never allowed, since the user cannot overrule a judgment they never saw. Being mid-workflow is not a reason to defer it.`
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
