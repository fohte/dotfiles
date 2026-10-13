#!/usr/bin/env bun
// Check a PR body draft against the rules that can be judged mechanically.
//
// Usage: lint-draft.ts [--owner <org>] [<draft>]
//
// Prints one line per violation and exits 1 if any is found.
// <draft> defaults to the output of `draft-path`, <org> to the current repo's owner.

import { execFileSync } from 'node:child_process'
import { readFileSync, realpathSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { parseArgs } from 'node:util'

type Report = (lineno: number, rule: string, message: string) => void

const TITLE_MAX = 50

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
      'write one sentence per item; split the rest into items or sub-bullets',
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

  let firstHeadingSeen = false
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
      if (firstHeadingSeen) inWhy = false
      firstHeadingSeen = true
      continue
    }

    if (item) {
      const content = item[2].trimEnd()
      const from = content.match(/^from:\s*(.*)$/)
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
  return errors
}

if (import.meta.main) {
  const { values, positionals } = parseArgs({
    options: { owner: { type: 'string' } },
    allowPositionals: true,
  })

  const scriptDir = dirname(realpathSync(import.meta.path))
  const draft =
    positionals[0] ??
    execFileSync(join(scriptDir, 'draft-path'), { encoding: 'utf8' }).trim()
  const owner =
    values.owner ??
    execFileSync(
      'gh',
      ['repo', 'view', '--json', 'owner', '--jq', '.owner.login'],
      {
        encoding: 'utf8',
      },
    ).trim()

  const errors = lint(readFileSync(draft, 'utf8'), owner)
  for (const [lineno, message] of errors) {
    console.log(`${draft}:${lineno}: ${message}`)
  }
  process.exit(errors.length > 0 ? 1 : 0)
}
