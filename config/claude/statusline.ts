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

function getColorForPercentage(percentage: number): string {
  if (percentage < 70) {
    return '\x1b[32m' // Green
  } else if (percentage < 90) {
    return '\x1b[33m' // Yellow
  } else {
    return '\x1b[31m' // Red
  }
}

// Unix epoch (秒) を Asia/Tokyo の "HH:mm" または "Ddd HH:mm" にフォーマット
// 24 時間以内なら時刻のみ、それ以上なら曜日を付ける
function formatResetTime(epochSeconds: number): string {
  const date = new Date(epochSeconds * 1000)
  const now = new Date()
  const diffMs = date.getTime() - now.getTime()
  const within24h = diffMs < 24 * 60 * 60 * 1000

  const time = date.toLocaleTimeString('en-GB', {
    timeZone: 'Asia/Tokyo',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  })

  if (within24h) {
    return time
  }

  const weekday = date.toLocaleDateString('en-US', {
    timeZone: 'Asia/Tokyo',
    weekday: 'short',
  })
  return `${weekday} ${time}`
}

function formatRateLimit(
  label: string,
  window: RateLimitWindow | undefined,
): string | null {
  if (!window || window.used_percentage === undefined) {
    return null
  }
  const pct = Math.round(window.used_percentage)
  const color = getColorForPercentage(pct)
  const reset = window.resets_at
    ? ` (→${formatResetTime(window.resets_at)})`
    : ''
  return `${color}${label} ${pct}%${reset}\x1b[0m`
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

  // Format output: Opus 4.1 | Tokens: 1.0k | Context: 10% | Session 33% (→15:30) | Week 6%
  const modelName = data.model?.display_name || 'Unknown'
  const tokensDisplay = formatTokens(totalTokens)

  const parts = [
    modelName,
    `Tokens: ${tokensDisplay}`,
    `${color}Context: ${percentage}%\x1b[0m`,
  ]

  const sessionPart = formatRateLimit('Session', data.rate_limits?.five_hour)
  if (sessionPart) parts.push(sessionPart)

  const weekPart = formatRateLimit('Week', data.rate_limits?.seven_day)
  if (weekPart) parts.push(weekPart)

  process.stdout.write(parts.join(' | '))
}

main().catch(console.error)
