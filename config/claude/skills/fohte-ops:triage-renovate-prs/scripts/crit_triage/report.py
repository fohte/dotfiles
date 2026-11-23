"""Report validation and HTML rendering."""
import html
import os
import re

from .template import TEMPLATE

LINK = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
CODE = re.compile(r"`([^`]+)`")
VERDICTS = {"merge", "auto", "delegate", "hold"}
GATE_ORDER = ("ci", "release", "order")
GATE_LABEL = {"ci": "CI", "release": "リリース", "order": "順序"}
IMPACT_LABEL = {"ok": ("なし", "None"), "warn": ("要対応", "Action needed")}
MAX_GATE_TEXT = 60
MAX_IMPACT_TEXT = 120
UPSTREAM_REF = re.compile(r"[\w.-]+/[\w.-]+#\d+|https?://")


def md(text):
    """Escape HTML, then re-enable inline code and links."""
    out = html.escape(str(text))
    out = LINK.sub(r'<a href="\2">\1</a>', out)
    return CODE.sub(r"<code>\1</code>", out)


def pr_key(number):
    """Radio group name, and the key the caller reads the approve/deny result by."""
    return f"pr-{number}"


def prop_key(index):
    """Radio group name for the `index`-th (1-based) proposal."""
    return f"prop-{index}"


def render_gates(gates, pr_num):
    unknown = set(gates) - set(GATE_ORDER)
    if unknown:
        raise SystemExit(f"#{pr_num}: unknown gates key(s): {sorted(unknown)}")
    parts = []
    for key in GATE_ORDER:
        gate = gates.get(key)
        if not gate:
            continue
        level = gate["level"]
        if level not in {"ok", "warn"}:
            raise SystemExit(f"#{pr_num}: unknown gates.{key}.level: {level}")
        text = gate["text"]
        if len(text) > MAX_GATE_TEXT:
            raise SystemExit(f"#{pr_num}: gates.{key}.text exceeds {MAX_GATE_TEXT} chars: {text}")
        body = md(text)
        if level == "warn":
            body = f'<span class="w">{body}</span>'
        parts.append(f"<i>{GATE_LABEL[key]}</i>{body}")
    return '<span class="sep">|</span>'.join(parts)


def render_change(change, pr_num, public):
    """Validate one change + its impact, and render its <tr>."""
    text = change["text"]
    if public and not change.get("text_en"):
        raise SystemExit(f"#{pr_num}: change is missing text_en (repo is public): {text}")

    impact = change.get("impact")
    if not impact:
        raise SystemExit(f"#{pr_num}: change is missing impact: {text}")
    level = impact["level"]
    if level not in {"ok", "warn"}:
        raise SystemExit(f"#{pr_num}: unknown impact.level: {level}")
    if len(impact["text"]) > MAX_IMPACT_TEXT:
        raise SystemExit(f"#{pr_num}: impact.text exceeds {MAX_IMPACT_TEXT} chars: {impact['text']}")
    if level == "warn" and not impact.get("action"):
        raise SystemExit(f"#{pr_num}: impact.level is warn but action is missing: {text}")
    if public and not impact.get("text_en"):
        raise SystemExit(f"#{pr_num}: impact is missing text_en (repo is public): {impact['text']}")

    mark = '<span class="bk">BREAKING</span>' if change.get("breaking") else ""
    what_td = f"<td>{mark}{md(text)}</td>"
    cls = " w" if level == "warn" else ""
    imp_td = f'<td class="imp{cls}">{IMPACT_LABEL[level][0]}</td>'
    detail = md(impact["text"])
    if level == "warn":
        detail += f'<span class="todo">→ {md(impact["action"])}</span>'
    detail_td = f'<td class="r{cls}">{detail}</td>'
    return f"<tr>{what_td}{imp_td}{detail_td}</tr>"


def render_changes(changes, pr_num, public):
    """Render the changes table. Empty input renders nothing -- nothing to report."""
    if not changes:
        return ""
    rows = "".join(render_change(c, pr_num, public) for c in changes)
    return (
        f'<table class="ev">\n'
        f"<caption>upstream の変更 {len(changes)} 件</caption>\n"
        f"<tr><th>なにがおきるか</th><th>影響</th><th>内容</th></tr>\n"
        f"{rows}\n"
        f"</table>"
    )


def derive_verdict(gates, changes):
    """The one-line verdict, derived from gates + changes so no one has to write it.

    `changes` must already be validated (every entry has "impact"."level") --
    call this only after render_changes() on the same list.
    """
    warn_changes = sum(1 for c in changes if c["impact"]["level"] == "warn")
    reasons = []
    if warn_changes:
        reasons.append(f"コード修正 {warn_changes} 件")
    order = gates.get("order")
    if order and order["level"] == "warn":
        reasons.append(order["text"])
    ci = gates.get("ci")
    # A failing CI check caused by a change already counted above isn't a second
    # reason -- it's the same reason showing up twice.
    if ci and ci["level"] == "warn" and not warn_changes:
        reasons.append("CI 調査中")
    release = gates.get("release")
    if release and release["level"] == "warn":
        reasons.append(release["text"])
    if not reasons:
        return "そのままマージしてよい", False
    return "今はマージできない — " + " / ".join(reasons), True


def _esc_cell(text):
    return text.replace("|", "\\|").replace("\n", " ")


def base_review_body(changes, public):
    """Build the approve-review comment from the validated changes table."""
    if not changes:
        return "📝\n\n" + ("No breaking changes." if public else "破壊的変更なし。")
    if public:
        header, sep = "| What changed | Impact here | Details |", "| --- | --- | --- |"
        rows = [
            "| {} | {} | {} |".format(
                _esc_cell(("**[BREAKING]** " if c.get("breaking") else "") + c["text_en"]),
                IMPACT_LABEL[c["impact"]["level"]][1],
                _esc_cell(c["impact"]["text_en"]),
            )
            for c in changes
        ]
    else:
        header, sep = "| なにがおきるか | 影響 | 内容 |", "| --- | --- | --- |"
        rows = [
            "| {} | {} | {} |".format(
                _esc_cell(("**[BREAKING]** " if c.get("breaking") else "") + c["text"]),
                IMPACT_LABEL[c["impact"]["level"]][0],
                _esc_cell(c["impact"]["text"]),
            )
            for c in changes
        ]
    return "📝\n\n" + "\n".join([header, sep, *rows])


def ai_footer():
    """Return the footer for the active coding agent, if one is identified."""
    if os.environ.get("CLAUDECODE"):
        return "🤖 Generated with [Claude Code](https://claude.com/claude-code)"
    if os.environ.get("CODEX_THREAD_ID"):
        return "🤖 Generated with [Codex](https://openai.com/codex)"
    return ""


def gen_review_body(changes, public, pr_num=None):
    """Generate the approve-review body, including its agent footer when available."""
    body = base_review_body(changes, public)
    if pr_num is not None:
        check_no_upstream_refs(body, pr_num)
    footer = ai_footer()
    return f"{body}\n\n{footer}" if footer else body


def check_no_upstream_refs(text, pr_num):
    """`owner/repo#123` and bare URLs turn into cross-references on someone else's repo."""
    m = UPSTREAM_REF.search(text)
    if m:
        raise SystemExit(f"#{pr_num}: generated review body references an upstream issue/PR or URL: {m.group(0)!r}")


def render_pr(pr, repo, public, has_scope, group_verdict):
    num = pr["number"]
    name = pr_key(num)
    url = html.escape(pr.get("url") or f"https://github.com/{repo}/pull/{num}")
    gates = pr.get("gates", {})
    changes = pr.get("changes", [])

    gates_html = render_gates(gates, num)
    changes_html = render_changes(changes, num, public)  # validates changes as a side effect

    verdict_text, blocked = derive_verdict(gates, changes)
    if group_verdict == "merge" and blocked:
        raise SystemExit(f"#{num}: in a merge group but its derived verdict blocks merging: {verdict_text}")

    review_body = None
    if group_verdict == "merge":
        review_body = gen_review_body(changes, public, pr_num=num)
        pr["review_body"] = review_body
    # Outside `merge` the toggle means "go ahead and delegate/hold/automerge this
    # PR", so it must never carry an approving review.
    if pr.get("review_body") and group_verdict != "merge":
        raise SystemExit(f"review_body on a {group_verdict} PR: #{num}")

    if has_scope:
        scope = html.escape(pr.get("scope", ""))
        left = f'<div class="gutter"><span class="num">#{num}</span><span class="scope">{scope}</span></div>'
        num_prefix = ""
    else:
        left = ""
        num_prefix = f'<span class="num">#{num}</span> '

    vers = pr.get("versions")
    vers_html = f'<div class="vers">{md(vers)}</div>' if vers else ""
    id_html = f'<div class="id">{num_prefix}<h5><a href="{url}">{html.escape(pr["title"])}</a></h5>{vers_html}</div>'

    gates_block = f'<div class="gates">{gates_html}</div>' if gates_html else ""
    gen_block = ""
    if review_body:
        gen_block = (
            '<div class="gen"><div class="cap">投稿されるコメント (上の表から自動生成)</div>'
            f"<pre>{html.escape(review_body)}</pre></div>"
        )

    verdict_cls = " w" if blocked else ""
    flat = "" if has_scope else " flat"

    return f"""<section class="pr{flat}">
  <div class="head">
    {left}
    {id_html}
    <div class="tg">
      <input type="radio" name="{name}" id="{name}-d" value="deny" checked
        /><label for="{name}-d" data-v="deny">deny</label
        ><input type="radio" name="{name}" id="{name}-a" value="approve"
        /><label for="{name}-a" data-v="approve">approve</label>
    </div>
  </div>
  <div class="verdict{verdict_cls}">{md(verdict_text)}</div>
  {gates_block}
  {changes_html}
  {gen_block}
</section>"""


def render_diff(diff_text):
    lines = []
    for line in diff_text.split("\n"):
        esc = html.escape(line)
        if line.startswith("-"):
            lines.append(f'<span class="m">{esc}</span>')
        elif line.startswith("+"):
            lines.append(f'<span class="p">{esc}</span>')
        else:
            lines.append(esc)
    return "\n".join(lines)


def render_risk(risk, idx):
    level = risk["level"]
    if level not in {"ok", "warn"}:
        raise SystemExit(f"unknown risks[{idx}].level: {level}")
    cls = " w" if level == "warn" else ""
    mark = "▲" if level == "warn" else "●"
    evidence = ""
    if risk.get("evidence"):
        evidence = f' <span class="why" title="{html.escape(risk["evidence"])}">根拠</span>'
    return f'<li class="{cls}">{mark} {md(risk["text"])}{evidence}</li>'


def render_proposal(proposal, idx):
    key = prop_key(idx)
    target = proposal["target"]
    if not target.get("why"):
        raise SystemExit(f"proposal {idx}: target.why is required")
    risks = proposal.get("risks") or []
    if not risks:
        raise SystemExit(f"proposal {idx}: risks is required")

    shared = target.get("shared", False)
    where = "共有 config" if shared else "このリポジトリ"
    tgt = f'変更先: <b>{html.escape(target["repo"])}</b> ({where})'
    risks_html = "".join(render_risk(r, i) for i, r in enumerate(risks))

    return f"""<div class="pcard">
  <div class="head">
    <div class="id">
      <h5>{md(proposal["title"])}</h5>
      <div class="tgt">{tgt}</div>
    </div>
    <div class="tg">
      <input type="radio" name="{key}" id="{key}-d" value="deny" checked
        /><label for="{key}-d" data-v="deny">deny</label
        ><input type="radio" name="{key}" id="{key}-a" value="approve"
        /><label for="{key}-a" data-v="approve">approve</label>
    </div>
  </div>
  <div class="sect">
    <div class="cap">なぜ{"共有 config か" if shared else "このリポジトリか"}</div>
    <p>{md(target["why"])}</p>
  </div>
  <div class="sect">
    <div class="cap">差分</div>
    <pre class="d">{render_diff(proposal.get("diff", ""))}</pre>
  </div>
  <div class="sect">
    <div class="cap">これが事故になるとき</div>
    <ul class="risk">{risks_html}</ul>
  </div>
  <div class="sect">
    <div class="cap">承認したら</div>
    <p>{md(proposal["on_approve"])}</p>
  </div>
</div>"""


def render(data, endpoint):
    repo = data["repo"]
    if "public" not in data:
        raise SystemExit("data.public is required (true for public non-Japanese repos)")
    public = data["public"]
    has_scope = any(pr.get("scope") for group in data["groups"] for pr in group["prs"])

    groups_html = []
    for group in data["groups"]:
        verdict = group["verdict"]
        if verdict not in VERDICTS:
            raise SystemExit(f"unknown verdict: {verdict}")
        prs = group["prs"]
        for pr in prs:
            if "review_body" in pr:
                raise SystemExit(f"#{pr['number']}: review_body must not be set in the input; it is generated")
        note = f'<span class="note">{md(group["note"])}</span>' if group.get("note") else ""
        pr_html = "".join(render_pr(pr, repo, public, has_scope, verdict) for pr in prs)
        groups_html.append(
            f'<div class="group">\n'
            f'  <h2>{html.escape(group["title"])} <span class="n">({len(prs)})</span>{note}</h2>\n'
            f"  {pr_html}\n"
            f"</div>"
        )

    proposals = data.get("proposals") or []
    proposals_html = ""
    if proposals:
        cards = "".join(render_proposal(p, i + 1) for i, p in enumerate(proposals))
        proposals_html = f"<h2>Renovate 設定変更の提案</h2>\n{cards}"

    total = sum(len(g["prs"]) for g in data["groups"]) + len(proposals)
    title = html.escape(data.get("title", "Triage"))

    # Literal replacement preserves the JavaScript template literals and object braces in TEMPLATE.
    out = TEMPLATE
    for token, value in {
        "__TITLE__": title,
        "__REPO__": html.escape(repo),
        "__GROUPS__": "".join(groups_html),
        "__PROPOSALS__": proposals_html,
        "__TOTAL__": str(total),
        "__ENDPOINT__": endpoint,
    }.items():
        out = out.replace(token, value)
    return out
