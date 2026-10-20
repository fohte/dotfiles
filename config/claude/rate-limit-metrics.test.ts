import { describe, expect, it } from 'bun:test'
import {
  mergeRateLimitSamples,
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
