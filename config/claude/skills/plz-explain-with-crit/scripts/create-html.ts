#!/usr/bin/env bun
import { writeFileSync, readFileSync } from 'node:fs'
import { parseArgs } from 'node:util'

const { values } = parseArgs({
  options: {
    title: { type: 'string' },
    output: { type: 'string' },
  },
})

if (values.title === undefined || values.output === undefined) {
  console.error('Usage: create-html.ts --title <title> --output <path>')
  process.exit(2)
}

const template = readFileSync(
  new URL('../assets/explainer.html', import.meta.url),
  'utf8',
)
const title = escapeHtml(values.title)
const html = template.replaceAll('{{TITLE}}', () => title)

try {
  writeFileSync(values.output, html, { encoding: 'utf8', flag: 'wx' })
} catch (error) {
  if ((error as NodeJS.ErrnoException).code === 'EEXIST') {
    console.error(`output already exists: ${values.output}`)
    process.exit(2)
  }
  throw error
}

function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (character) => {
    switch (character) {
      case '&':
        return '&amp;'
      case '<':
        return '&lt;'
      case '>':
        return '&gt;'
      case '"':
        return '&quot;'
      case "'":
        return '&#39;'
      default:
        return character
    }
  })
}
