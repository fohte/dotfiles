#!/usr/bin/env bun

import {
  readdir,
  readFile,
  rename,
  rm,
  stat,
  writeFile,
} from 'node:fs/promises'
import { readFileSync, realpathSync, type Dirent } from 'node:fs'
import { homedir } from 'node:os'
import { dirname, join, resolve } from 'node:path'

const OTLP_METRICS_URL =
  'https://alloy-otlp-home-k8s.tail8f0aa.ts.net/v1/metrics'
const SESSION_ID_PATTERN = /^[A-Za-z0-9_-]+$/
const TEMPORARY_FILE_PATTERN = /\.json\.\d+\.[0-9a-f-]+\.tmp$/
const TEMPORARY_FILE_MAX_AGE_SECONDS = 600
const MAX_SENDER_LOG_BYTES = 64 * 1024
const WINDOW_NAMES = ['five_hour', 'seven_day'] as const

export type RateLimitWindowName = (typeof WINDOW_NAMES)[number]

export interface RateLimitSample {
  usedPercentage: number
  resetsAt: number
  observedAt: number
}

export type RateLimitSamples = Partial<
  Record<RateLimitWindowName, RateLimitSample>
>

export interface RateLimitInput {
  five_hour?: { used_percentage?: number; resets_at?: number }
  seven_day?: { used_percentage?: number; resets_at?: number }
}

function isRateLimitSample(
  value: unknown,
  now: number,
): value is RateLimitSample {
  if (typeof value !== 'object' || value === null) return false

  const sample = value as Partial<RateLimitSample>
  return (
    typeof sample.usedPercentage === 'number' &&
    Number.isFinite(sample.usedPercentage) &&
    sample.usedPercentage >= 0 &&
    sample.usedPercentage <= 100 &&
    typeof sample.resetsAt === 'number' &&
    Number.isFinite(sample.resetsAt) &&
    sample.resetsAt > now &&
    typeof sample.observedAt === 'number' &&
    Number.isFinite(sample.observedAt)
  )
}

function isBetterSample(candidate: RateLimitSample, current: RateLimitSample) {
  if (candidate.resetsAt !== current.resetsAt) {
    return candidate.resetsAt > current.resetsAt
  }
  if (candidate.usedPercentage !== current.usedPercentage) {
    return candidate.usedPercentage > current.usedPercentage
  }
  return candidate.observedAt > current.observedAt
}

function chooseSample(
  current: RateLimitSample | undefined,
  candidate: RateLimitSample | undefined,
): RateLimitSample | undefined {
  if (!candidate) return current
  if (!current || isBetterSample(candidate, current)) return candidate
  return current
}

export function mergeRateLimitSamples(
  existing: RateLimitSamples | undefined,
  incoming: RateLimitInput | undefined,
  now: number,
  observedAt = now,
): RateLimitSamples {
  const merged: RateLimitSamples = {}

  for (const window of WINDOW_NAMES) {
    const previous = isRateLimitSample(existing?.[window], now)
      ? existing[window]
      : undefined
    const input = incoming?.[window]
    const candidate =
      input?.used_percentage !== undefined && input.resets_at !== undefined
        ? {
            usedPercentage: input.used_percentage,
            resetsAt: input.resets_at,
            observedAt,
          }
        : undefined
    const winner = chooseSample(
      previous,
      isRateLimitSample(candidate, now) ? candidate : undefined,
    )

    if (winner) merged[window] = winner
  }

  return merged
}

export function selectRateLimitSamples(
  sessions: readonly RateLimitSamples[],
  now: number,
): RateLimitSamples {
  const selected: RateLimitSamples = {}

  for (const session of sessions) {
    for (const window of WINDOW_NAMES) {
      const candidate = session[window]
      if (!isRateLimitSample(candidate, now)) continue
      selected[window] = chooseSample(selected[window], candidate)
    }
  }

  return selected
}

async function writeSnapshot(path: string, samples: RateLimitSamples) {
  const temporaryPath = `${path}.${process.pid}.${crypto.randomUUID()}.tmp`

  try {
    await writeFile(temporaryPath, `${JSON.stringify(samples)}\n`, {
      mode: 0o600,
    })
    await rename(temporaryPath, path)
  } finally {
    await rm(temporaryPath, { force: true })
  }
}

async function readSnapshot(
  path: string,
): Promise<RateLimitSamples | undefined> {
  try {
    const value: unknown = JSON.parse(await readFile(path, 'utf8'))
    if (typeof value !== 'object' || value === null) return undefined
    return value as RateLimitSamples
  } catch {
    return undefined
  }
}

async function isDirectory(path: string) {
  try {
    return (await stat(path)).isDirectory()
  } catch {
    return false
  }
}

export function getRole(): string | null {
  try {
    const scriptPath = realpathSync(import.meta.path)
    const dotfilesDir = resolve(dirname(scriptPath), '..', '..')
    const content = readFileSync(join(dotfilesDir, '.role'), 'utf8')
    for (const line of content.split('\n')) {
      const trimmed = line.trim()
      if (!trimmed || trimmed.startsWith('#')) continue
      return trimmed.split(/\s+/)[0] || null
    }
  } catch {
    return null
  }
  return null
}

export function getRateLimitStateDir(): string {
  return join(homedir(), '.local', 'state', 'claude-rate-limits')
}

export async function recordRateLimitSnapshot(
  stateDir: string,
  sessionId: string,
  incoming: RateLimitInput,
  observedAt = Math.floor(Date.now() / 1000),
) {
  if (!SESSION_ID_PATTERN.test(sessionId) || !(await isDirectory(stateDir))) {
    return
  }

  const path = join(stateDir, `${sessionId}.json`)
  const existing = await readSnapshot(path)
  const merged = mergeRateLimitSamples(existing, incoming, observedAt)

  if (Object.keys(merged).length === 0) {
    await rm(path, { force: true })
    return
  }

  await writeSnapshot(path, merged)
}

function parseSnapshot(value: unknown, now: number): RateLimitSamples {
  if (typeof value !== 'object' || value === null) return {}

  const stored = value as RateLimitSamples
  const samples: RateLimitSamples = {}
  for (const window of WINDOW_NAMES) {
    const sample = stored[window]
    if (isRateLimitSample(sample, now)) samples[window] = sample
  }
  return samples
}

async function pruneStaleTemporaryFiles(
  stateDir: string,
  entries: readonly Dirent[],
  now: number,
) {
  for (const entry of entries) {
    if (!entry.isFile() || !TEMPORARY_FILE_PATTERN.test(entry.name)) continue

    const path = join(stateDir, entry.name)
    try {
      const details = await stat(path)
      if (
        now - Math.floor(details.mtimeMs / 1000) >
        TEMPORARY_FILE_MAX_AGE_SECONDS
      ) {
        await rm(path, { force: true })
      }
    } catch {
      // A concurrent statusline update may already have renamed the file.
    }
  }
}

async function loadSessionSnapshot(path: string, now: number) {
  const stored = await readSnapshot(path)
  const samples = parseSnapshot(stored, now)

  if (Object.keys(samples).length === 0) {
    await rm(path, { force: true })
    return undefined
  }

  if (JSON.stringify(samples) !== JSON.stringify(stored)) {
    await writeSnapshot(path, samples)
  }
  return samples
}

async function loadCurrentSessions(stateDir: string, now: number) {
  const sessions: RateLimitSamples[] = []
  const entries = await readdir(stateDir, { withFileTypes: true })
  await pruneStaleTemporaryFiles(stateDir, entries, now)

  for (const entry of entries) {
    if (!entry.isFile() || !entry.name.endsWith('.json')) continue
    const sessionId = entry.name.slice(0, -'.json'.length)
    if (!SESSION_ID_PATTERN.test(sessionId)) continue

    const samples = await loadSessionSnapshot(join(stateDir, entry.name), now)
    if (samples) sessions.push(samples)
  }

  return sessions
}

function buildOtlpRequest(samples: RateLimitSamples, now: number) {
  const timeUnixNano = (BigInt(now) * 1_000_000_000n).toString()
  const metrics = [
    ['claude_rate_limit_used_percent', 'usedPercentage'],
    ['claude_rate_limit_reset_at_seconds', 'resetsAt'],
    ['claude_rate_limit_observed_at_seconds', 'observedAt'],
  ] as const

  return {
    resourceMetrics: [
      {
        resource: {
          attributes: [
            { key: 'service.name', value: { stringValue: 'claude-code' } },
          ],
        },
        scopeMetrics: [
          {
            scope: { name: 'fohte.claude-rate-limits' },
            metrics: metrics.map(([name, valueKey]) => ({
              name,
              gauge: {
                dataPoints: WINDOW_NAMES.flatMap((window) => {
                  const sample = samples[window]
                  return sample
                    ? [
                        {
                          attributes: [
                            { key: 'window', value: { stringValue: window } },
                          ],
                          timeUnixNano,
                          asDouble: sample[valueKey],
                        },
                      ]
                    : []
                }),
              },
            })),
          },
        ],
      },
    ],
  }
}

export async function exportRateLimitMetrics(
  stateDir: string,
  now = Math.floor(Date.now() / 1000),
  send: typeof fetch = fetch,
) {
  if (!(await isDirectory(stateDir))) return

  const sessions = await loadCurrentSessions(stateDir, now)
  const samples = selectRateLimitSamples(sessions, now)
  if (Object.keys(samples).length === 0) return

  const response = await send(OTLP_METRICS_URL, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(buildOtlpRequest(samples, now)),
    signal: AbortSignal.timeout(10_000),
  })

  if (!response.ok) {
    throw new Error(
      `OTLP metrics request failed with status ${response.status}`,
    )
  }
}

async function main() {
  if (getRole() !== 'private') return

  const stateDir = getRateLimitStateDir()
  await trimSenderLog(stateDir)
  await exportRateLimitMetrics(stateDir)
}

async function trimSenderLog(stateDir: string) {
  const path = join(stateDir, 'sender.log')
  try {
    if ((await stat(path)).size > MAX_SENDER_LOG_BYTES) {
      await writeFile(path, '')
    }
  } catch {
    // launchd may not have created the log yet.
  }
}

if (import.meta.main) {
  main().catch((error) => {
    const message = error instanceof Error ? error.message : String(error)
    console.error(
      `Claude rate limit export failed: ${message.replace(/\s+/g, ' ').slice(0, 500)}`,
    )
    process.exitCode = 1
  })
}
