#!/usr/bin/env bun
// Check a PR body draft against the rules that can be judged mechanically.
//
// Usage: lint-draft.ts [--owner <org>] [--visibility <PUBLIC|PRIVATE>] [<draft>]
//
// Prints one line per violation and exits 1 if any is found.
// <draft> defaults to the output of `draft-path`, <org> and <visibility> to the
// current repo's. In a public repo, every URL is fetched without credentials.

import { execFileSync } from 'node:child_process'
import { readFileSync, realpathSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { parseArgs } from 'node:util'

type Report = (lineno: number, rule: string, message: string) => void

const TITLE_MAX = 50
const SECTION_MAX_ITEMS = 2
// Why and What only: Design decisions may need a longer table.
const LIMITED_SECTIONS = 2

const LIST_ITEM = /^(\s*)(?:[-*+]|\d+[.)])\s+(.*)$/
const FENCE = /^\s*(```|~~~)/
// Only the opening clause matters: "〜とき、" / "〜ので、" put the condition before the subject.
const WHY_CONDITIONAL =
  /^[^、。]*(とき|時|ので)(は|に|には)?、|^(When|If|Since|Because|Without)\b/
const BARE_URL = /^https?:\/\/\S+$/
// The lookbehind skips redirect.github.com and other subdomains.
const GITHUB_ORG = /(?<![\w.-])github\.com\/([\w.-]+)/g
const BLOB_REF = /github\.com\/[\w.-]+\/[\w.-]+\/blob\/([^/\s)]+)\//g
const SHA = /^[0-9a-f]{7,40}$/
// Requires a space before "(" so a trailing markdown link `[text](url)` does not match.
const TRAILING_PAREN = /(\s\([^()]*\)|（[^（）]*）)$/
const POLITE_END =
  /(です|ます|ました|でした|ません|ましょう|でしょう|ください)$/

function splitFrontmatter(text: string) {
  const lines = text.split('\n')
  if (lines[0] === '---') {
    const end = lines.indexOf('---', 1)
    if (end !== -1) {
      return {
        frontmatter: lines.slice(1, end),
        body: lines.slice(end + 1),
        offset: end + 1,
      }
    }
  }
  return { frontmatter: [], body: lines, offset: 0 }
}

function parseTitle(frontmatter: string[]) {
  for (const [i, line] of frontmatter.entries()) {
    const m = line.match(/^title:\s*(.*)$/)
    if (!m) continue
    let value = m[1].trim()
    const quote = value[0]
    if (
      value.length >= 2 &&
      (quote === "'" || quote === '"') &&
      value.at(-1) === quote
    ) {
      value = value.slice(1, -1)
      if (quote === "'") value = value.replaceAll("''", "'")
    }
    // +2 for the opening `---` and 1-based numbering.
    return { title: value, lineno: i + 2 }
  }
  return undefined
}

function checkSentenceEnd(content: string, lineno: number, report: Report) {
  // Quoted text such as an error message may contain its own 。.
  const prose = content
    .replace(/。$/, '')
    .replace(/`[^`]*`|「[^「」]*」|『[^『』]*』/g, '')
  if (prose.includes('。')) {
    report(
      lineno,
      'Rule 15',
      'write one sentence per item; cut it down instead of splitting',
    )
  }
  if (content.endsWith('。')) {
    report(lineno, 'Rule 15', 'drop the trailing `。`')
  } else if (POLITE_END.test(content)) {
    report(lineno, 'Rule 15', 'write in plain form, not です/ます')
  }
}

export function lint(text: string, owner: string): [number, string][] {
  const errors: [number, string][] = []
  const report: Report = (lineno, rule, message) => {
    errors.push([lineno, `${rule}: ${message}`])
  }

  const { frontmatter, body, offset } = splitFrontmatter(text)

  const title = parseTitle(frontmatter)
  // Spread to count code points, not UTF-16 units.
  const titleLength = title ? [...title.title].length : 0
  if (title && titleLength > TITLE_MAX) {
    report(
      title.lineno,
      'Rule 1',
      `title is ${titleLength} characters (max ${TITLE_MAX})`,
    )
  }

  // Tag fenced code instead of dropping it: examples inside are not linted, but
  // a fence inside a list item still counts as list content for Rule 12.
  let inFence = false
  const lines = body.map((line) => {
    if (FENCE.test(line)) {
      inFence = !inFence
      return { line, isCode: true }
    }
    return { line, isCode: inFence }
  })

  let headingIndex = 0
  let inWhy = true
  let prevInList = false
  let blankSincePrev = false
  let fromBlock:
    { lineno: number; indent: number; children: string[] } | undefined

  const closeFromBlock = () => {
    if (fromBlock && fromBlock.children.length < 2) {
      report(
        fromBlock.lineno,
        'Rule 5',
        'write a single `from:` link on one line as `- from: <URL>`',
      )
    }
    fromBlock = undefined
  }

  let section: { lineno: number; items: number } | undefined
  const closeSection = () => {
    if (section && section.items > SECTION_MAX_ITEMS) {
      report(
        section.lineno,
        'Rule 14',
        `section has ${section.items} items (max ${SECTION_MAX_ITEMS}); drop what the reviewer does not need`,
      )
    }
    section = undefined
  }

  for (const [i, { line, isCode }] of lines.entries()) {
    const lineno = i + 1 + offset
    const stripped = line.trim()

    if (!stripped) {
      if (!isCode) blankSincePrev = true
      continue
    }

    const item = isCode ? null : line.match(LIST_ITEM)
    const indent = line.length - line.trimStart().length
    const continuesList = item !== null || (prevInList && indent > 0)

    if (blankSincePrev && prevInList && continuesList) {
      report(lineno, 'Rule 12', 'remove the blank line inside the list')
    }
    blankSincePrev = false
    prevInList = continuesList

    if (isCode) continue

    if (line.includes('<!--')) {
      report(lineno, 'template', 'remove the template comment')
    }

    for (const m of line.matchAll(GITHUB_ORG)) {
      if (m[1].toLowerCase() !== owner.toLowerCase()) {
        report(lineno, 'Rule 5', `link to \`${m[1]}\` via redirect.github.com`)
      }
    }
    for (const m of line.matchAll(BLOB_REF)) {
      if (!SHA.test(m[1])) {
        report(
          lineno,
          'Rule 5',
          `use a commit SHA permalink instead of \`blob/${m[1]}/\``,
        )
      }
    }

    if (fromBlock) {
      if (indent > fromBlock.indent && item) {
        if (BARE_URL.test(item[2])) {
          fromBlock.children.push(item[2])
        } else {
          report(lineno, 'Rule 5', 'list only bare URLs under `from:`')
        }
        continue
      }
      closeFromBlock()
    }

    if (line.startsWith('## ')) {
      closeSection()
      headingIndex++
      inWhy = headingIndex <= 1
      if (headingIndex <= LIMITED_SECTIONS) section = { lineno, items: 0 }
      continue
    }
    // Template subsections such as Reproduction steps are not counted.
    if (line.startsWith('### ')) {
      closeSection()
      continue
    }

    if (item) {
      const content = item[2].trimEnd()
      const from = content.match(/^from:\s*(.*)$/)
      if (section && !from) section.items++
      if (from) {
        const rest = from[1]
        if (rest === '') {
          fromBlock = { lineno, indent, children: [] }
        } else if (!BARE_URL.test(rest) || rest.includes(',')) {
          report(
            lineno,
            'Rule 5',
            'write `from:` as `- from: <URL>` with a bare URL and nothing else',
          )
        }
        continue
      }

      if (inWhy && WHY_CONDITIONAL.test(content)) {
        report(
          lineno,
          'Rule 3',
          'start with the subject and conclusion, not a condition',
        )
      }
      if (TRAILING_PAREN.test(content)) {
        report(
          lineno,
          'Rule 10',
          'move the trailing parenthetical into a sub-bullet',
        )
      }
      checkSentenceEnd(content, lineno, report)
    } else if (stripped.startsWith('|')) {
      const cells = stripped
        .replace(/^\||\|$/g, '')
        .split('|')
        .map((c) => c.trim())
      if (!cells.every((c) => /^:?-+:?$/.test(c))) {
        for (const cell of cells) checkSentenceEnd(cell, lineno, report)
      }
    }
  }

  closeFromBlock()
  closeSection()
  return errors
}

const URL_IN_TEXT = /https?:\/\/[^\s<>()`'"]+[^\s<>()`'".,;:!?]/g
const MAX_REDIRECTS = 5

// Redirects that stay public: github.com serves attachments from
// githubusercontent.com, and redirect.github.com forwards to github.com.
const ALLOWED_HOPS: [RegExp, RegExp][] = [
  [/^github\.com$/, /\.githubusercontent\.com$/],
  [/^redirect\.github\.com$/, /^github\.com$/],
]

const isAllowedHop = (from: string, to: string) =>
  from === to ||
  from === `www.${to}` ||
  to === `www.${from}` ||
  ALLOWED_HOPS.some(([f, t]) => f.test(from) && t.test(to))

const PRIVATE_ADDRESS =
  /^(10\.|127\.|169\.254\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.|100\.(6[4-9]|[7-9]\d|1[01]\d|12[0-7])\.)/

// Ask a public resolver, not this machine's, so hosts that only resolve over a
// VPN or local DNS are caught.
async function publicDnsError(host: string): Promise<string | undefined> {
  // No public page is linked by an IPv6 literal, and the brackets in
  // URL.hostname would defeat an address match anyway.
  if (host.startsWith('[')) return 'is an IP address, not a public site'
  if (/^[\d.]+$/.test(host)) {
    return PRIVATE_ADDRESS.test(host)
      ? 'points to a private address'
      : undefined
  }
  const addresses: string[] = []
  for (const type of ['A', 'AAAA']) {
    const res = await fetch(
      `https://cloudflare-dns.com/dns-query?name=${host}&type=${type}`,
      {
        headers: { accept: 'application/dns-json' },
        signal: AbortSignal.timeout(10_000),
      },
    )
    if (!res.ok) throw new Error(`public DNS returned ${res.status}`)
    const body = (await res.json()) as {
      Answer?: { type: number; data: string }[]
    }
    for (const a of body.Answer ?? []) {
      if (a.type === 1) addresses.push(a.data)
      // Any IPv6 address outside 2000::/3 is not globally routable.
      if (a.type === 28 && !/^[23]/.test(a.data)) {
        return `${host} resolves to a private address`
      }
    }
  }
  if (addresses.length === 0) return `${host} does not resolve in public DNS`
  if (addresses.some((a) => PRIVATE_ADDRESS.test(a))) {
    return `${host} resolves to a private address`
  }
  return undefined
}

// Without credentials, a private page answers 401/403/404 or redirects to a
// login page. Anything that cannot be confirmed public fails, because a leak
// cannot be undone after the PR is posted.
async function publicReachError(url: string): Promise<string | undefined> {
  try {
    let current = new URL(url)
    for (let hop = 0; hop <= MAX_REDIRECTS; hop++) {
      const dnsError = await publicDnsError(current.hostname)
      if (dnsError) return dnsError
      const res = await fetch(current, {
        redirect: 'manual',
        signal: AbortSignal.timeout(10_000),
      })
      if (res.status >= 300 && res.status < 400) {
        const next = new URL(res.headers.get('location') ?? '', current)
        if (!isAllowedHop(current.hostname, next.hostname)) {
          return `redirects to ${next.hostname}, likely a login page`
        }
        current = next
        continue
      }
      if (!res.ok) return `returns ${res.status} without credentials`
      return undefined
    }
    return 'redirects too many times'
  } catch (e) {
    return `could not be confirmed public (${(e as Error).message}); retry, or remove it`
  }
}

export async function lintPublicUrls(text: string) {
  const found = text.split('\n').flatMap((line, i) =>
    [...line.matchAll(URL_IN_TEXT)].map((m) => ({
      lineno: i + 1,
      url: m[0],
    })),
  )
  const reaches = await Promise.all(found.map((f) => publicReachError(f.url)))
  const errors: [number, string][] = []
  for (const [i, error] of reaches.entries()) {
    const { lineno, url } = found[i]
    if (error) {
      errors.push([
        lineno,
        `Rule 5: ${url} ${error}; a public PR must link only to public pages`,
      ])
    }
  }
  return errors
}

const VISIBILITIES = ['PUBLIC', 'PRIVATE', 'INTERNAL']

if (import.meta.main) {
  const { values, positionals } = parseArgs({
    options: { owner: { type: 'string' }, visibility: { type: 'string' } },
    allowPositionals: true,
  })

  const scriptDir = dirname(realpathSync(import.meta.path))
  const draft =
    positionals[0] ??
    execFileSync(join(scriptDir, 'draft-path'), { encoding: 'utf8' }).trim()
  const repo =
    values.owner && values.visibility
      ? undefined
      : (JSON.parse(
          execFileSync('gh', ['repo', 'view', '--json', 'owner,visibility'], {
            encoding: 'utf8',
          }),
        ) as { owner: { login: string }; visibility: string })
  const owner = values.owner ?? repo!.owner.login
  const visibility = (values.visibility ?? repo!.visibility).toUpperCase()
  if (!VISIBILITIES.includes(visibility)) {
    console.error(
      `Error: --visibility must be one of ${VISIBILITIES.join(', ')}`,
    )
    process.exit(2)
  }

  const text = readFileSync(draft, 'utf8')
  const errors = lint(text, owner)
  if (visibility === 'PUBLIC') {
    errors.push(...(await lintPublicUrls(text)))
    errors.sort((a, b) => a[0] - b[0])
  }
  for (const [lineno, message] of errors) {
    console.log(`${draft}:${lineno}: ${message}`)
  }
  process.exit(errors.length > 0 ? 1 : 0)
}
