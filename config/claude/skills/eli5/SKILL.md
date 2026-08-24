---
name: eli5
description: Explain a topic like I'm a 5 year old. Use when the user types /eli5 <topic> or asks for a dead-simple picture explainer of how something works.
---

# eli5

Explain like I'm someone who knows nothing about this topic, using a HTML artifact with big pictures and few words.

Topic: $ARGUMENTS

## Deliver it in crit

Do not answer in the chat. Write the HTML as a single self-contained file and open it with crit, so the reader can select any part of it and ask a follow-up right there. Only if crit cannot be launched at all, say so and answer in the chat instead.

Invoke the `plz-explain-with-crit` skill (Skill tool, or `/plz-explain-with-crit`) and follow it together with its `references/generated-html.md` for the whole loop: background launch, reporting the URL, picking up the questions the user leaves as comments, and replying on crit. Its `## 作るかどうか` rule (no diagram, so answer in the chat instead) does not apply — for this skill the explainer itself is the artifact, always open it.
