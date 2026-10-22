---
name: tq
description: 'Read and write the user''s personal task manager (tq, https://tq.fohte.net) with the `tq` CLI. TRIGGER whenever the user refers to their own tasks, projects, or task pages — "タスクに追加して", "今日のタスク", "この調査結果を page に残して", "tq の #58 見て", a tq.fohte.net URL, or a bare task number in that context. Also trigger when writing up a design doc, investigation report, or HTML visualization that should live on a task rather than in a scratch file, and when attaching a screenshot, image, or video to a task or page. SKIP for in-session TODO tracking (use TodoWrite) and for GitHub issues (use the github-issue skill).'
---

# tq CLI

`tq` is the CLI for the user's personal task manager. It covers the whole REST API; use it instead of hitting the API directly.

Resources: `task`, `page`, `comment`, `project`, `label`, `asset`, `github`, `checklist`, `today`, `calendar`, `slack`, `health`.

`tq task get <id>` includes checklist trees and leaf-item progress for completion checks.

## Name yourself with `--author`

tq records who made each write and treats an unattributed one as the user's own. Pass your own model name (e.g. `my-agent`) so your edits are not logged as theirs. It is a global option, so it goes before the resource, and runok refuses `tq` without it.

```bash
tq --author my-agent task complete <task-id> --reason completed
```

The examples below leave it out to keep them readable; every real invocation still needs it.

## Discover flags from `--help`, don't guess them

The CLI derives its flags, choices, validation, and help text from the API's zod schemas, so `--help` is always current while anything written down here can go stale. Run `tq <resource> <subcommand> --help` before a command you haven't used in this session.

If a command is unknown or its syntax is unclear, read `tq <resource> --help` before trying another spelling or alias. Use the listed command for the operation; do not infer one from another resource or tool.

```bash
tq task --help          # subcommands of a resource
tq page create --help   # flags of one subcommand
```

## Pass long content as a file path, never inline

This is the main reason the CLI exists. Page and comment bodies are often tens of kB; putting them in a command line means paying for the whole body in context. Write the body to a file, then hand over the path — the content never enters the conversation.

Create each temporary file with `mktemp "$AGENT_TMPDIR/tq-<purpose>.XXXXXX"`. Use its full output verbatim when writing the file and in later `--file` or `--output` calls. Placeholders such as `<design-path>` below stand for the full path printed by `mktemp`.

```bash
# Example: run this first and use its full output as <design-path> below.
mktemp "$AGENT_TMPDIR/tq-design.XXXXXX"
```

```bash
tq page create 58 '設計' --file <design-path>
tq page update 58 <pageId> --file <design-path>
tq comment create 58 --file <comment-path>
```

Reading works the same way in reverse: `--output` writes the body to a file instead of stdout, so you can grep or read only the part you need.

```bash
tq page list 58                                   # metadata + pageId, no bodies
tq page get 58 <pageId> --output <page-body-path> # body to disk, not to context
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
tq page create 58 'アーキテクチャ図' --format html --file <diagram-path>
```

## Compress images and videos before uploading

`tq asset upload` stores the file as-is, and every page view downloads it at that size. The server also rejects files over its size limit with 413. Shrink the file first, even when the original is under the limit: a page only needs enough resolution to read the content.

- Screenshots and other images: convert to WebP, and scale down when the source is larger than the page shows (e.g. a Retina capture).
- Videos: re-encode to H.264 MP4 with a lower resolution and frame rate, and drop the audio track unless it matters.

```bash
magick <src> -resize '1600x1600>' -quality 80 <dst>.webp
ffmpeg -i <src> -vf 'scale=-2:min(720\,ih),fps=15' -c:v libx264 -crf 28 -preset slow -an -movflags +faststart <dst>.mp4
tq asset upload <dst>.mp4
```

## Close or delete tasks

Task status and closure reason describe different things. Close a task with `tq task complete <id> --reason <reason>` and choose the reason that matches the work:

LLM authors must provide `--reason` explicitly.

- `completed`: the work is done.
- `not_planned`: the task was created by mistake or the work will not be done. This keeps the task number, pages, and comments available, so use it to cancel work instead of deleting its record.
- `duplicate`: another task already tracks the same work. Add `--duplicate-of <taskId>` when the existing task is known.

Use `tq task reopen <id>` to return a completed task to todo. Physical deletion removes the task and can also remove related pages or comments. It requires an explicit `--confirm-delete <id>` that resolves to the same task; the confirmation can be included on the first call. Delete only when that loss is intended.

```bash
tq task complete <task-id> --reason not_planned
tq task complete <duplicate-task-id> --reason duplicate --duplicate-of <existing-task-id>
tq task reopen <task-id>
tq task delete <task-id> --confirm-delete <task-id>
```

## Common flows

```bash
# Today's tasks
tq today get "$(gdate +%F)"

# Find a task, then read one of its pages
tq task search 'CLI' --status todo
tq page list 58

# Capture an investigation result on the task it belongs to
tq page create 58 '調査メモ' --file <findings-path>

# Move a task along
tq task complete <task-id> --reason completed
```
