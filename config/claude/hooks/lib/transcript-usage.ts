import { readFileSync } from 'node:fs'

// Claude Code auto-compacts at 80% of the model's context window. statusline.ts
// and context-split-guard.ts both express usage as a percentage of this
// threshold (not the raw window size) so the two numbers stay comparable.
export const AUTO_COMPACT_RATIO = 0.8

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

// Sum of token types on the last assistant message's usage, which reflects
// the full context size sent on that turn's API request (not cumulative
// across turns).
export function readTotalTokens(transcriptPath: string): number {
  try {
    const content = readFileSync(transcriptPath, 'utf8')
    const lines = content.trim().split('\n')

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

    if (!lastUsage) return 0
    return (
      (lastUsage.input_tokens || 0) +
      (lastUsage.output_tokens || 0) +
      (lastUsage.cache_creation_input_tokens || 0) +
      (lastUsage.cache_read_input_tokens || 0)
    )
  } catch {
    return 0
  }
}
