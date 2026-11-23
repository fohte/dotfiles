"""HTML template used by the triage report renderer."""

TEMPLATE = """<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8" />
<title>__TITLE__</title>
<style>
:root {
  --bg: #14161a; --card: #1c1f25; --card2: #16181d; --line: #2c313a; --line2: #232830;
  --fg: #e3e6ea; --dim: #8b939f; --dimmer: #5f6773;
  --act: #e2b04a; /* the only semantic color: needs action */
}
* { box-sizing: border-box; }
body {
  margin: 0; padding: 2rem 2rem 6rem; background: var(--bg); color: var(--fg);
  font: 15px/1.6 -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif;
}
.wrap { max-width: 960px; margin: 0 auto; }
h1 { font-size: 1.35rem; margin: 0 0 1.5rem; }
h2 { font-size: 0.95rem; margin: 2.2rem 0 0.8rem; padding-left: 0.6rem; border-left: 3px solid var(--dimmer); }
h2 .n { color: var(--dim); font-weight: 400; }
h2 .note { display: block; font-size: 0.8rem; font-weight: 400; color: var(--dim); margin-top: 0.15rem; }
code {
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 0.86em;
  background: #0f1114; padding: 0.1em 0.4em; border-radius: 3px;
}
a { color: inherit; text-decoration: underline; text-decoration-color: var(--dimmer); }

.group { margin-bottom: 2.2rem; }

.pr { background: var(--card); border: 1px solid var(--line); border-radius: 8px; margin-bottom: 0.9rem; overflow: hidden; }
.pr .head { padding: 0.9rem 1rem 0.75rem; display: flex; gap: 0.9rem; align-items: flex-start; }
.pr .gutter { flex: none; width: 4.6rem; font-family: ui-monospace, monospace; padding-top: 0.1rem; }
.pr .gutter .num { display: block; color: var(--dimmer); font-size: 0.86rem; }
.pr .gutter .scope { display: block; color: var(--fg); font-size: 0.8rem; letter-spacing: 0.06em; margin-top: 0.15rem; }
.pr .id { flex: 1; min-width: 0; }
.pr .id > .num { color: var(--dimmer); font-family: ui-monospace, monospace; font-size: 0.86rem; }
.pr h5 { font-size: 1rem; font-weight: 600; margin: 0; }
.pr.flat .id h5 { display: inline; }
.pr .vers { font-family: ui-monospace, monospace; font-size: 0.78rem; color: var(--dimmer); margin-top: 0.25rem; }

.tg { flex: none; display: flex; border: 1px solid var(--line); border-radius: 6px; overflow: hidden; font-size: 0.76rem; }
.tg input { position: absolute; opacity: 0; pointer-events: none; }
.tg label { padding: 0.28rem 0.8rem; cursor: pointer; color: var(--dimmer); user-select: none; }
.tg label + input + label { border-left: 1px solid var(--line); }
.tg input:checked + label { background: #303640; color: var(--fg); }
.tg input:focus-visible + label { outline: 2px solid var(--act); outline-offset: -2px; }

.pr .verdict { padding: 0 1rem 0.5rem 6.5rem; font-size: 1.08rem; font-weight: 600; }
.pr .verdict.w { color: var(--act); }
.pr.flat .verdict { padding-left: 1rem; }
.pr .gates { padding: 0 1rem 1rem 6.5rem; font-size: 0.84rem; color: var(--dim); }
.pr.flat .gates { padding-left: 1rem; }
.pr .gates i { font-style: normal; color: var(--dimmer); font-size: 0.76rem; margin-right: 0.3rem; }
.pr .gates .sep { color: var(--line); margin: 0 0.55rem; }
.pr .gates .w { color: var(--act); }

table.ev { width: 100%; border-collapse: collapse; font-size: 0.88rem; }
table.ev caption { caption-side: top; text-align: left; font-size: 0.74rem; letter-spacing: 0.05em; color: var(--dimmer); padding: 0.5rem 1rem 0.4rem; border-top: 1px solid var(--line); background: var(--card2); }
table.ev th { text-align: left; font-weight: 600; font-size: 0.74rem; color: var(--dimmer); letter-spacing: 0.04em; padding: 0 1rem 0.45rem; border-bottom: 1px solid var(--line); background: var(--card2); }
table.ev td { padding: 0.6rem 1rem; border-bottom: 1px solid var(--line2); vertical-align: top; }
table.ev tr:last-child td { border-bottom: none; }
table.ev td.imp { width: 4.6rem; color: var(--dimmer); white-space: nowrap; }
table.ev td.imp.w { color: var(--act); font-weight: 600; }
table.ev td.r { color: var(--dim); }
table.ev td.r.w { color: var(--act); }
.bk { font-family: ui-monospace, monospace; font-size: 0.68rem; letter-spacing: 0.08em; color: var(--dimmer); border: 1px solid var(--line); border-radius: 3px; padding: 0 0.3rem; margin-right: 0.4rem; vertical-align: 1px; }
.todo { display: block; margin-top: 0.3rem; color: var(--act); }

.gen { border-top: 1px solid var(--line); padding: 0.7rem 1rem 0.9rem; }
.gen .cap { color: var(--dimmer); font-size: 0.76rem; letter-spacing: 0.05em; margin-bottom: 0.5rem; }
.gen pre { margin: 0; padding: 0.7rem 0.85rem; background: #0f1114; border-radius: 5px; white-space: pre; overflow-x: auto; font-size: 0.72rem; line-height: 1.6; font-family: ui-monospace, monospace; color: var(--dim); }

.pr:has(input[value='approve']:checked) .verdict,
.pr:has(input[value='approve']:checked) .gates,
.pr:has(input[value='approve']:checked) table.ev,
.pr:has(input[value='approve']:checked) .gen { display: none; }

.pcard { background: var(--card); border: 1px solid var(--line); border-radius: 8px; margin-bottom: 0.9rem; overflow: hidden; }
.pcard .head { padding: 0.9rem 1rem 0.75rem; display: flex; gap: 1rem; align-items: flex-start; }
.pcard .id { flex: 1; }
.pcard h5 { margin: 0; font-size: 1rem; font-weight: 600; }
.pcard .tgt { font-size: 0.8rem; color: var(--dimmer); margin-top: 0.3rem; }
.pcard .sect { border-top: 1px solid var(--line); padding: 0.7rem 1rem; font-size: 0.88rem; }
.pcard .sect .cap { color: var(--dimmer); font-size: 0.74rem; letter-spacing: 0.05em; margin-bottom: 0.35rem; }
.pcard .sect p { margin: 0; color: var(--dim); }
.pcard pre.d { margin: 0; padding: 0.6rem 0.8rem; background: #0f1114; border-radius: 5px; font-size: 0.76rem; line-height: 1.6; font-family: ui-monospace, monospace; color: var(--dim); overflow-x: auto; white-space: pre-wrap; }
.pcard pre.d .m { color: #b0655e; }
.pcard pre.d .p { color: #5c9c85; }
.pcard ul.risk { margin: 0; padding-left: 1.1rem; color: var(--dim); }
.pcard ul.risk li { margin-bottom: 0.35rem; }
.pcard ul.risk li.w { color: var(--act); }
.why { color: var(--dimmer); font-size: 0.76rem; text-decoration: underline; text-decoration-style: dotted; cursor: help; }

.pcard:has(input[value='approve']:checked) .sect { display: none; }

.bar {
  position: fixed; left: 0; right: 0; bottom: 0; padding: 0.7rem 2rem; background: #0f1114;
  border-top: 1px solid var(--line); display: flex; gap: 1.2rem; align-items: baseline; font-size: 0.85rem;
}
.bar b { color: var(--fg); font-size: 1rem; }
.bar .hint { color: var(--dim); }
#saved { margin-left: auto; color: var(--dim); font-family: ui-monospace, monospace; font-size: 0.78rem; }
</style>
</head>
<body>
<div class="wrap">
<h1>__TITLE__ — <a href="https://github.com/__REPO__">__REPO__</a></h1>
__GROUPS__
__PROPOSALS__
</div>

<div class="bar">
  <span>approve <b id="count">0</b> / __TOTAL__</span>
  <span class="hint">deny が既定。PR の承認 = この対応方針で進め投稿コメントをそのまま GitHub に出してよい。提案の承認 = 変更に着手してよい。指摘・質問は crit のコメントで</span>
  <span id="saved">…</span>
</div>

<script>
const API = 'http://127.0.0.1:__ENDPOINT__'
const saved = document.getElementById('saved')
const count = document.getElementById('count')
const radios = [...document.querySelectorAll('.tg input')]
const names = [...new Set(radios.map((r) => r.name))]

const collect = () =>
  Object.fromEntries(names.map((n) => [n, document.querySelector(`input[name="${n}"]:checked`).value]))

const render = (s) => (count.textContent = Object.values(s).filter((v) => v === 'approve').length)

const save = () => {
  const s = collect()
  render(s)
  fetch(API, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(s) })
    .then(() => (saved.textContent = 'saved ' + new Date().toLocaleTimeString()))
    .catch((e) => (saved.textContent = 'POST failed: ' + e))
}

fetch(API)
  .then((r) => r.json())
  .then((s) => {
    Object.entries(s).forEach(([n, v]) => {
      const el = document.querySelector(`input[name="${n}"][value="${v}"]`)
      if (el) el.checked = true
    })
    render(collect())
    saved.textContent = 'loaded'
  })
  .catch((e) => (saved.textContent = 'GET failed: ' + e))

radios.forEach((r) => r.addEventListener('change', save))
</script>
</body>
</html>
"""
