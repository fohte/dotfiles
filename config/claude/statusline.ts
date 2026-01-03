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

  // Auto-compact threshold is 80% of 200K tokens
  const autoCompactThreshold = 160_000
  const percentage = Math.round((totalTokens / autoCompactThreshold) * 100)
  const color = getColorForPercentage(percentage)

  // Format output: Opus 4.1 | Tokens: 1.0k | Context: 10%
  const modelName = data.model?.display_name || 'Unknown'
  const tokensDisplay = formatTokens(totalTokens)

  process.stdout.write(
    `${modelName} | Tokens: ${tokensDisplay} | ${color}Context: ${percentage}%\x1b[0m`,
  )
}

main().catch(console.error)
