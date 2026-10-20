import { describe, expect, it } from 'bun:test'
import { mkdtemp, readFile, readdir, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import {
  exportRateLimitMetrics,
  mergeRateLimitSamples,
  recordRateLimitSnapshot,
  selectRateLimitSamples,
  type RateLimitSamples,
} from './rate-limit-metrics.ts'

describe('selectRateLimitSamples', () => {
  it('selects the sample with the latest reset time per window', () => {
    const sessions: RateLimitSamples[] = [
      {
        five_hour: { usedPercentage: 80, resetsAt: 200, observedAt: 100 },
      },
      {
        five_hour: { usedPercentage: 20, resetsAt: 300, observedAt: 110 },
      },
    ]

    expect(selectRateLimitSamples(sessions, 150)).toEqual({
      five_hour: { usedPercentage: 20, resetsAt: 300, observedAt: 110 },
    })
  })

  it('selects the highest usage when reset times match', () => {
    const sessions: RateLimitSamples[] = [
      {
        seven_day: { usedPercentage: 35, resetsAt: 300, observedAt: 100 },
      },
      {
        seven_day: { usedPercentage: 55, resetsAt: 300, observedAt: 110 },
      },
    ]

    expect(selectRateLimitSamples(sessions, 150)).toEqual({
      seven_day: { usedPercentage: 55, resetsAt: 300, observedAt: 110 },
    })
  })

  it('omits expired windows', () => {
    const sessions: RateLimitSamples[] = [
      {
        five_hour: { usedPercentage: 99, resetsAt: 150, observedAt: 100 },
      },
    ]

    expect(selectRateLimitSamples(sessions, 150)).toEqual({})
  })

  it('selects each window independently', () => {
    const sessions: RateLimitSamples[] = [
      {
        five_hour: { usedPercentage: 45, resetsAt: 400, observedAt: 120 },
      },
      {
        seven_day: { usedPercentage: 30, resetsAt: 500, observedAt: 100 },
      },
    ]

    expect(selectRateLimitSamples(sessions, 150)).toEqual({
      five_hour: { usedPercentage: 45, resetsAt: 400, observedAt: 120 },
      seven_day: { usedPercentage: 30, resetsAt: 500, observedAt: 100 },
    })
  })
})

describe('mergeRateLimitSamples', () => {
  it('does not regress when a session reports a stale snapshot', () => {
    const existing: RateLimitSamples = {
      five_hour: { usedPercentage: 45, resetsAt: 300, observedAt: 120 },
    }

    expect(
      mergeRateLimitSamples(
        existing,
        { five_hour: { used_percentage: 20, resets_at: 300 } },
        150,
        130,
      ),
    ).toEqual({
      five_hour: existing.five_hour,
    })
  })

  it('retains an omitted window until it expires', () => {
    const existing: RateLimitSamples = {
      seven_day: { usedPercentage: 25, resetsAt: 500, observedAt: 120 },
    }

    expect(
      mergeRateLimitSamples(
        existing,
        { five_hour: { used_percentage: 20, resets_at: 300 } },
        150,
        130,
      ),
    ).toEqual({
      five_hour: { usedPercentage: 20, resetsAt: 300, observedAt: 130 },
      seven_day: existing.seven_day,
    })
  })
})

describe('exportRateLimitMetrics', () => {
  it('does not rewrite a snapshot when one window expires', async () => {
    const stateDir = await mkdtemp(join(tmpdir(), 'claude-rate-limits-'))

    try {
      const snapshotPath = join(stateDir, 'session_a.json')
      await recordRateLimitSnapshot(
        stateDir,
        'session_a',
        {
          five_hour: { used_percentage: 80, resets_at: 950 },
          seven_day: { used_percentage: 20, resets_at: 8_000 },
        },
        900,
      )
      const snapshotBeforeExport = await readFile(snapshotPath, 'utf8')

      let requestBody = ''
      const send: typeof fetch = async (_input, init) => {
        requestBody = String(init?.body)
        return new Response(null, { status: 200 })
      }

      await exportRateLimitMetrics(stateDir, 1_000, send)

      const metrics =
        JSON.parse(requestBody).resourceMetrics[0].scopeMetrics[0].metrics
      expect(
        metrics.map(
          (metric: {
            gauge: {
              dataPoints: Array<{
                attributes: Array<{ value: { stringValue: string } }>
              }>
            }
          }) =>
            metric.gauge.dataPoints.map(
              (point) => point.attributes[0].value.stringValue,
            ),
        ),
      ).toEqual([['seven_day'], ['seven_day'], ['seven_day']])
      expect(await readFile(snapshotPath, 'utf8')).toBe(snapshotBeforeExport)
    } finally {
      await rm(stateDir, { recursive: true, force: true })
    }
  })

  it('exports the selected session samples as OTLP gauges', async () => {
    const stateDir = await mkdtemp(join(tmpdir(), 'claude-rate-limits-'))

    try {
      await recordRateLimitSnapshot(
        stateDir,
        'session_a',
        {
          five_hour: { used_percentage: 80, resets_at: 2_000 },
          seven_day: { used_percentage: 20, resets_at: 8_000 },
        },
        900,
      )
      await recordRateLimitSnapshot(
        stateDir,
        'session_b',
        {
          five_hour: { used_percentage: 30, resets_at: 3_000 },
          seven_day: { used_percentage: 50, resets_at: 8_000 },
        },
        950,
      )
      await recordRateLimitSnapshot(
        stateDir,
        'expired_session',
        { five_hour: { used_percentage: 99, resets_at: 950 } },
        900,
      )

      let requestUrl = ''
      let requestInit: RequestInit | undefined
      const send: typeof fetch = async (input, init) => {
        requestUrl = String(input)
        requestInit = init
        return new Response(null, { status: 200 })
      }

      await exportRateLimitMetrics(stateDir, 1_000, send)

      const payload = JSON.parse(String(requestInit?.body))
      const metrics = payload.resourceMetrics[0].scopeMetrics[0].metrics

      expect({
        requestUrl,
        method: requestInit?.method,
        sessionFiles: (await readdir(stateDir)).sort(),
        metricNames: metrics.map((metric: { name: string }) => metric.name),
        hasUnits: metrics.some((metric: { unit?: string }) => 'unit' in metric),
        dataPoints: metrics.map(
          (metric: {
            gauge: {
              dataPoints: Array<{
                attributes: Array<{
                  key: string
                  value: { stringValue: string }
                }>
                asDouble: number
                timeUnixNano: string
              }>
            }
          }) =>
            metric.gauge.dataPoints.map((point) => ({
              window: point.attributes[0].value.stringValue,
              value: point.asDouble,
              timeUnixNano: point.timeUnixNano,
            })),
        ),
      }).toEqual({
        requestUrl: 'https://alloy-otlp-home-k8s.tail8f0aa.ts.net/v1/metrics',
        method: 'POST',
        sessionFiles: ['session_a.json', 'session_b.json'],
        metricNames: [
          'claude_rate_limit_used_percent',
          'claude_rate_limit_reset_at_seconds',
          'claude_rate_limit_observed_at_seconds',
        ],
        hasUnits: false,
        dataPoints: [
          [
            { window: 'five_hour', value: 30, timeUnixNano: '1000000000000' },
            { window: 'seven_day', value: 50, timeUnixNano: '1000000000000' },
          ],
          [
            {
              window: 'five_hour',
              value: 3_000,
              timeUnixNano: '1000000000000',
            },
            {
              window: 'seven_day',
              value: 8_000,
              timeUnixNano: '1000000000000',
            },
          ],
          [
            { window: 'five_hour', value: 950, timeUnixNano: '1000000000000' },
            { window: 'seven_day', value: 950, timeUnixNano: '1000000000000' },
          ],
        ],
      })
    } finally {
      await rm(stateDir, { recursive: true, force: true })
    }
  })
})
