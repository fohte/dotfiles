---
name: crafting-effective-readmes
description: Use when writing or improving README files. Not all READMEs are the same — provides templates and guidance matched to your audience and project type.
---

# Crafting Effective READMEs

## Overview

READMEs answer questions your audience will have. Different audiences need different information - a contributor to an OSS project needs different context than future-you opening a config folder.

**Always ask:** Who will read this, and what do they need to know?

## Scope and source boundaries

The README documents **this repository**, not its ecosystem. Background context the user provides in the prompt — surrounding infrastructure, sibling repos, deploy mechanics — is for your own understanding, not content to transcribe. Filter every fact through these rules before writing it.

- **Document only what lives in this repo.** In scope: code, config, build, runtime behavior driven by files here. Out of scope: how a separate repo deploys this service, what tool watches its image, how upstream systems provision its secrets, how webhooks are registered by an external IaC repo. Those facts belong in the owning repo's docs.
- **Abstract external dependencies to the boundary.** When readers genuinely need to know an external system exists, name only the seam — the protocol, capability, or requirement that this repo depends on (e.g. "a reverse proxy in front of this service is required"). Do not name internal paths, tool choices, secret-store paths, hostnames, module names, or any implementation detail owned by the other system — those rot independently of this repo and expose internals the reader cannot act on from here.
- **Public repo, private source = do not write it.** If the fact's source of truth is a private repo or private system, it does not go in a public repo's README, even if the user pasted it into the prompt. Treat private context as reference material for your reasoning, never as draft content. When in doubt about whether a repo is public, ask.
- **Ground limiting claims in this repo's code.** Statements that narrow scope ("from X organization", "only Y event types", "runs on Z") must be backed by a check visible in code or config. If no such check exists, generalize ("from configured repositories", "selected events") rather than asserting a limit that the code does not actually enforce.
- **Don't outsource scope to a named external repo or system.** Wording of the form "handled in `<another repo>`", "managed by `<another system>`", "deployed by `<some pipeline>`" is a scope violation even when intended as an "out of scope" marker — it leaks the existence of a sibling/private system and leaves the reader unable to reproduce anything on their own. If a requirement lives outside this repo, state it as a requirement on the environment that any operator can satisfy in any setup. Never write "X is done in `<some-repo>`".
- **Write for a reader who only has this repo.** Public-repo readers arrive with nothing but a clone. If a section only makes sense to someone who also has access to a sibling/private repo, you've either misidentified the audience or under-specified what this repo needs from its environment. Rewrite the requirement so it stands on its own — concrete enough that any operator can satisfy it from this repo alone, not so prescriptive that you transcribe the other system's implementation.

A scope violation has two failure modes that look like opposites but are both wrong:

- **Over-transcribe**: copy the other system's implementation (its config files, its module names, its hostnames).
- **Over-outsource**: punt requirements to a named external repo or system, leaving the reader unable to reproduce.

The fix in both cases is the same: state the requirement on the environment at the right altitude — concrete enough to act on, abstract enough that this repo isn't claiming to own another system's choices.

## Process

### Step 1: Identify the Task

**Ask:** "What README task are you working on?"

| Task          | When                                   |
| ------------- | -------------------------------------- |
| **Creating**  | New project, no README yet             |
| **Adding**    | Need to document something new         |
| **Updating**  | Capabilities changed, content is stale |
| **Reviewing** | Checking if README is still accurate   |

### Step 2: Task-Specific Questions

**Creating initial README:**

1. What type of project? (see Project Types below)
2. What problem does this solve in one sentence?
3. What's the quickest path to "it works"?
4. Anything notable to highlight?

**Adding a section:**

1. What needs documenting?
2. Where should it go in the existing structure?
3. Who needs this info most?

**Updating existing content:**

1. What changed?
2. Read current README, identify stale sections
3. Propose specific edits

**Reviewing/refreshing:**

1. Read current README
2. Check against actual project state (package.json, main files, etc.)
3. Flag outdated sections
4. Update "Last reviewed" date if present

### Step 3: Always Ask

After drafting, ask: **"Anything else to highlight or include that I might have missed?"**

## Project Types

| Type            | Audience                      | Key Sections                             | Template                  |
| --------------- | ----------------------------- | ---------------------------------------- | ------------------------- |
| **Open Source** | Contributors, users worldwide | Install, Usage, Contributing, License    | `templates/oss.md`        |
| **Personal**    | Future you, portfolio viewers | What it does, Tech stack, Learnings      | `templates/personal.md`   |
| **Internal**    | Teammates, new hires          | Setup, Architecture, Runbooks            | `templates/internal.md`   |
| **Config**      | Future you (confused)         | What's here, Why, How to extend, Gotchas | `templates/xdg-config.md` |

**Ask the user** if unclear. Don't assume OSS defaults for everything.

## Essential Sections (All Types)

Every README needs at minimum:

1. **Name** - Self-explanatory title
2. **Description** - What + why in 1-2 sentences
3. **Usage** - How to use it (examples help)

## References

- `section-checklist.md` - Which sections to include by project type
- `style-guide.md` - Common README mistakes and prose guidance
- `using-references.md` - Guide to deeper reference materials
