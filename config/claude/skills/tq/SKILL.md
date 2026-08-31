---
name: tq
description: 'Read and write the user''s personal task manager (tq, https://tq.fohte.net) with the `tq` CLI. TRIGGER whenever the user refers to their own tasks, projects, or task pages — "タスクに追加して", "今日のタスク", "この調査結果を page に残して", "tq の #58 見て", a tq.fohte.net URL, or a bare task number in that context. Also trigger when writing up a design doc, investigation report, or HTML visualization that should live on a task rather than in a scratch file. SKIP for in-session TODO tracking (use TodoWrite) and for GitHub issues (use the github-issue skill).'
---

# tq CLI

`tq` is the CLI for the user's personal task manager. It covers the whole REST API; use it instead of hitting the API directly.

Resources: `task`, `page`, `comment`, `project`, `label`, `image`, `github`, `today`, `calendar`, `slack`, `health`.

## Name yourself with `--author`

tq records who made each write and treats an unattributed one as the user's own. Pass your own model name (e.g. `claude-opus-5`) so your edits are not logged as theirs. It is a global option, so it goes before the resource, and runok refuses `tq` without it.

```bash
tq --author claude-opus-5 task complete 58
```

The examples below leave it out to keep them readable; every real invocation still needs it.

## Discover flags from `--help`, don't guess them

The CLI derives its flags, choices, validation, and help text from the API's zod schemas, so `--help` is always current while anything written down here can go stale. Run `tq <resource> <subcommand> --help` before a command you haven't used in this session.

```bash
tq task --help          # subcommands of a resource
tq page create --help   # flags of one subcommand
```

## Pass long content as a file path, never inline

This is the main reason the CLI exists. Page and comment bodies are often tens of kB; putting them in a command line means paying for the whole body in context. Write the body to a file, then hand over the path — the content never enters the conversation.

```bash
tq page create 58 '設計' --file /tmp/design.md
tq page update 58 <pageId> --file /tmp/design.md
tq comment create 58 --file /tmp/note.md
```

Content also reads from stdin when `--file` is omitted, which is fine for a couple of lines.

Reading works the same way in reverse: `--output` writes the body to a file instead of stdout, so you can grep or read only the part you need.

```bash
tq page list 58                                   # metadata + pageId, no bodies
tq page get 58 <pageId> --output /tmp/design.md   # body to disk, not to context
tq page get 58 <pageId>                           # body to stdout, only if it is short
```

## Lists omit long fields by default

`task list`, `task search`, `page list`, and `comment list` leave out descriptions and bodies. `--full` puts them back — reach for it only when you actually need every body, since it is the expensive mode.

## Task IDs

Anywhere a task ID is taken, both the short task number (`58`) and the UUID work. A `https://tq.fohte.net/tasks/<uuid>` URL therefore needs no lookup — pass the UUID straight through.

## Cross-reference other systems by URL, not by `#number`

Inside descriptions, page bodies, and comments, `#58` renders as a link to tq task 58. A pull request or issue written as a bare `#140` therefore becomes a link to an unrelated tq task. Write the full URL for anything that does not live in tq, and keep the number in the link text when you want it readable. When a full link would be noise (a passing mention in prose, not a reference worth clicking), wrap the number in a code span instead — a code span never resolves as a tq reference, but a bare number does regardless of where it sits in the sentence.

```md
<!-- bad: renders as a link to tq task 140 -->

| #140 | search fix |

Also fixed the same regression as #140.

<!-- good -->

| [my-app #140](https://github.com/acme/my-app/pull/140) | search fix |

Also fixed the same regression as [my-app #140](https://github.com/acme/my-app/pull/140).
```

This bites in summary write-ups (a table of bare PR numbers) and in ordinary prose alike — a passing mention like "fixed the same bug as #140" is just as easy to type without thinking. Before posting a body that references another system, grep it for `#<digits>`.

## HTML pages

`--format html` renders the page as a full HTML document inside a sandboxed iframe: no access to the app's cookies, localStorage, or API. Inline all CSS and JS instead of referencing external files, since nothing guarantees an external resource is still reachable when the page is opened months later.

```bash
tq page create 58 'アーキテクチャ図' --format html --file /tmp/diagram.html
```

## Common flows

```bash
# Today's tasks
tq today get "$(gdate +%F)"

# Find a task, then read one of its pages
tq task search 'CLI' --status todo
tq page list 58

# Capture an investigation result on the task it belongs to
tq page create 58 '調査メモ' --file /tmp/findings.md

# Move a task along
tq task complete 58
```
