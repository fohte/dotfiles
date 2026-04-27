#!/usr/bin/env bun

interface SessionData {
  model: {
    display_name: string
  }
  workspace: {
    current_dir: string
  }
  transcript_path?: string
  session_id?: string
  cwd?: string
  version?: string
  rate_limits?: {
    five_hour?: RateLimitWindow
    seven_day?: RateLimitWindow
    seven_day_opus?: RateLimitWindow
  }
  context_window?: {
    context_window_size?: number
  }
}

interface RateLimitWindow {
  used_percentage?: number
  resets_at?: number // Unix epoch seconds
}

interface TranscriptEntry {
  type: string
  message?: {
    usage?: {
      input_tokens?: number
      output_tokens?: number
      cache_creation_input_tokens?: number
      cache_read_input_tokens?: number
    }
  }
}

function formatTokens(tokens: number): string {
  if (tokens >= 1_000_000) {
    return `${(tokens / 1_000_000).toFixed(1)}M`
  } else if (tokens >= 1_000) {
    return `${(tokens / 1_000).toFixed(1)}k`
  }
  return tokens.toString()
}

// モデル名と context window サイズに応じた表示色を返す
// Opus は紫系、Sonnet は緑系、1M context のときは明るめのトーンにする
function getModelColor(displayName: string, contextWindow: number): string {
  const is1M = contextWindow >= 1_000_000
  const lower = displayName.toLowerCase()
  if (lower.includes('opus')) {
    return is1M ? '\x1b[38;5;177m' : '\x1b[38;5;141m'
  }
  if (lower.includes('sonnet')) {
    return is1M ? '\x1b[38;5;120m' : '\x1b[38;5;71m'
  }
  if (lower.includes('haiku')) {
    return '\x1b[38;5;215m'
  }
  return '\x1b[38;5;215m'
}

function getColorForPercentage(percentage: number): string {
  if (percentage < 70) {
    return '\x1b[32m' // Green
  } else if (percentage < 90) {
    return '\x1b[33m' // Yellow
  } else {
    return '\x1b[31m' // Red
  }
}

// 現在時刻からの残り秒数を "Xh Ym" / "XdYh" / "Ym" 形式にフォーマット
function formatRemaining(epochSeconds: number): string {
  const diffSec = Math.max(0, epochSeconds - Math.floor(Date.now() / 1000))
  const days = Math.floor(diffSec / 86400)
  const hours = Math.floor((diffSec % 86400) / 3600)
  const minutes = Math.floor((diffSec % 3600) / 60)

  if (days > 0) {
    return `${days}d${hours}h`
  }
  if (hours > 0) {
    return `${hours}h${minutes.toString().padStart(2, '0')}m`
  }
  return `${minutes}m`
}

const WINDOW_DURATION_SEC = {
  five_hour: 5 * 3600,
  seven_day: 7 * 86400,
} as const

// pace_ratio = 使用率 / 経過率。1.0 超なら現ペースで窓終了前に上限到達する
// 窓開始からの経過が短いと値が暴れるため、最低経過率に達するまで undefined を返す
function computePaceRatio(
  window: RateLimitWindow,
  windowDurationSec: number,
): number | undefined {
  if (window.used_percentage === undefined || window.resets_at === undefined) {
    return undefined
  }
  const remainingSec = window.resets_at - Math.floor(Date.now() / 1000)
  const elapsedSec = windowDurationSec - remainingSec
  const elapsedRatio = elapsedSec / windowDurationSec
  // 経過 5% 未満は分母が小さすぎて不安定なので算出しない
  if (elapsedRatio < 0.05) {
    return undefined
  }
  const usedRatio = window.used_percentage / 100
  return usedRatio / elapsedRatio
}

function formatPace(ratio: number | undefined): string {
  if (ratio === undefined) {
    return ''
  }
  // 基準ペース 100% として N% で表示。<100% は dim、100-150% は黄、150% 以上は赤
  const pct = Math.round(ratio * 100)
  if (ratio < 1.0) {
    return ` \x1b[90m✓ ${pct}%\x1b[0m`
  }
  if (ratio < 1.5) {
    return ` \x1b[33m⚠ ${pct}%\x1b[0m`
  }
  return ` \x1b[31m🔥 ${pct}%\x1b[0m`
}

function formatRateLimit(
  label: string,
  window: RateLimitWindow | undefined,
  windowDurationSec: number,
): string | null {
  if (!window || window.used_percentage === undefined) {
    return null
  }
  const pct = Math.round(window.used_percentage)
  const color = getColorForPercentage(pct)
  const remaining = window.resets_at
    ? ` \x1b[90m(${formatRemaining(window.resets_at)})\x1b[0m`
    : ''
  const pace = formatPace(computePaceRatio(window, windowDurationSec))
  return `${label}: ${color}${pct}%\x1b[0m${remaining}${pace}`
}

async function main() {
  const input = await Bun.stdin.text()
  const data: SessionData = JSON.parse(input)

  // Calculate total tokens from transcript file
  let totalTokens = 0

  if (data.transcript_path) {
    try {
      const file = Bun.file(data.transcript_path)
      const content = await file.text()
      const lines = content.trim().split('\n')

      // Get only the last assistant message with usage info
      let lastUsage = null

      for (const line of lines) {
        try {
          const entry: TranscriptEntry = JSON.parse(line)
          if (entry.type === 'assistant' && entry.message?.usage) {
            lastUsage = entry.message.usage
          }
        } catch {
          // Skip invalid JSON lines
        }
      }

      // Use the cumulative tokens from the last assistant message
      if (lastUsage) {
        totalTokens =
          (lastUsage.input_tokens || 0) +
          (lastUsage.output_tokens || 0) +
          (lastUsage.cache_creation_input_tokens || 0) +
          (lastUsage.cache_read_input_tokens || 0)
      }
    } catch (error) {
      // If we can't read the transcript, tokens remain 0
    }
  }

  // Auto-compact threshold is 80% of the model's context window
  const contextWindow = data.context_window?.context_window_size ?? 200_000
  const autoCompactThreshold = contextWindow * 0.8
  const percentage = Math.round((totalTokens / autoCompactThreshold) * 100)
  const color = getColorForPercentage(percentage)

  // Format output: Opus 4.7 [1M] | 1.0k tok (10%) | 5h: 33% (4h50m) / 7d: 6% (1d17h) | v2.1.119 (Claude Code)
  const reset = '\x1b[0m'
  const dim = '\x1b[90m'

  const modelName = data.model?.display_name || 'Unknown'
  const modelColor = getModelColor(modelName, contextWindow)
  const is1M = contextWindow >= 1_000_000
  const contextLabel = is1M && !/1m/i.test(modelName) ? ' [1M]' : ''
  const tokensDisplay = formatTokens(totalTokens)

  const parts: string[] = []
  parts.push(`${modelColor}${modelName}${contextLabel}${reset}`)
  parts.push(`${tokensDisplay} tok (${color}${percentage}%${reset})`)

  const sessionPart = formatRateLimit(
    '5h',
    data.rate_limits?.five_hour,
    WINDOW_DURATION_SEC.five_hour,
  )
  const weekPart = formatRateLimit(
    '7d',
    data.rate_limits?.seven_day,
    WINDOW_DURATION_SEC.seven_day,
  )
  const limitParts = [sessionPart, weekPart].filter(
    (p): p is string => p !== null,
  )
  if (limitParts.length > 0) {
    parts.push(limitParts.join(' / '))
  }

  if (data.version) {
    parts.push(`${dim}v${data.version} (Claude Code)${reset}`)
  }

  process.stdout.write(parts.join(' | '))
}

main().catch(console.error)
