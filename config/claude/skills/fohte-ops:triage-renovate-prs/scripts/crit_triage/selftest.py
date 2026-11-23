"""Existing inline selftest for report rendering and GitHub actions."""
import html
import io
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from .actions import act_on_approvals
from .report import (
    ai_footer,
    check_no_upstream_refs,
    derive_verdict,
    gen_review_body,
    md,
    pr_key,
    prop_key,
    render,
    render_change,
    render_changes,
    render_diff,
    render_gates,
    render_pr,
    render_proposal,
)

def selftest():
    assert md("a<b & `x` [t](http://e/?a=1&b=2)") == (
        'a&lt;b &amp; <code>x</code> <a href="http://e/?a=1&amp;b=2">t</a>'
    )

    assert render_gates({}, 1) == ""
    g = render_gates({"ci": {"level": "ok", "text": "全 check green"}}, 1)
    assert g == "<i>CI</i>全 check green"
    g = render_gates({"order": {"level": "warn", "text": "[#118](url) が先"}}, 1)
    assert g == '<i>順序</i><span class="w"><a href="url">#118</a> が先</span>'
    try:
        render_gates({"ci": {"level": "warn", "text": "x" * 61}}, 1)
        assert False, "should reject overlong gate text"
    except SystemExit:
        pass
    try:
        render_gates({"ci": {"level": "maybe", "text": "x"}}, 1)
        assert False, "should reject unknown gate level"
    except SystemExit:
        pass

    ok_change = {"text": "t", "impact": {"level": "ok", "text": "i"}}
    warn_change = {
        "text": "t2",
        "text_en": "t2en",
        "breaking": True,
        "impact": {"level": "warn", "text": "i2", "text_en": "i2en", "action": "do x"},
    }
    row = render_changes([ok_change, warn_change], 1, public=False)
    assert '<span class="bk">BREAKING</span>' in row
    assert '<td class="imp w">要対応</td>' in row
    assert '<span class="todo">→ do x</span>' in row
    assert "upstream の変更 2 件" in row

    try:
        render_changes([{"text": "t", "impact": {"level": "warn", "text": "i"}}], 1, public=False)
        assert False, "warn impact without action should be rejected"
    except SystemExit:
        pass
    try:
        render_changes([{"text": "t", "impact": {"level": "ok", "text": "i" * 121}}], 1, public=False)
        assert False, "overlong impact text should be rejected"
    except SystemExit:
        pass
    try:
        render_changes([{"text": "t", "impact": {"level": "ok", "text": "i"}}], 1, public=True)
        assert False, "public repo without text_en should be rejected"
    except SystemExit:
        pass

    assert derive_verdict({}, []) == ("そのままマージしてよい", False)
    assert derive_verdict({"ci": {"level": "ok", "text": "x"}}, [ok_change]) == ("そのままマージしてよい", False)
    assert derive_verdict({}, [warn_change]) == ("今はマージできない — コード修正 1 件", True)
    text, blocked = derive_verdict({"order": {"level": "warn", "text": "#118 のマージ待ち"}}, [warn_change])
    assert blocked and text == "今はマージできない — コード修正 1 件 / #118 のマージ待ち", text
    # A CI failure caused by the already-counted warn change isn't a second reason.
    text, _ = derive_verdict({"ci": {"level": "warn", "text": "x"}}, [warn_change])
    assert text == "今はマージできない — コード修正 1 件", text
    # An uncaused CI failure is its own reason.
    text, _ = derive_verdict({"ci": {"level": "warn", "text": "x"}}, [])
    assert text == "今はマージできない — CI 調査中", text

    footer = f"\n\n{ai_footer()}" if ai_footer() else ""
    assert gen_review_body([], public=False) == "📝\n\n破壊的変更なし。" + footer
    assert gen_review_body([], public=True) == "📝\n\nNo breaking changes." + footer
    body = gen_review_body([ok_change, warn_change], public=False)
    assert "| t | なし | i |" in body
    assert "| **[BREAKING]** t2 | 要対応 | i2 |" in body
    body_en = gen_review_body([warn_change], public=True)
    assert "| **[BREAKING]** t2en | Action needed | i2en |" in body_en
    # A pipe in the content must not break the table.
    piped = gen_review_body([{"text": "a|b", "impact": {"level": "ok", "text": "c|d"}}], public=False)
    assert "a\\|b" in piped and "c\\|d" in piped

    try:
        check_no_upstream_refs("see acme/widget#42 for details", 1)
        assert False, "owner/repo#N reference should be rejected"
    except SystemExit:
        pass
    try:
        check_no_upstream_refs("see https://github.com/acme/widget/releases", 1)
        assert False, "upstream URL should be rejected"
    except SystemExit:
        pass
    check_no_upstream_refs("no references here", 1)  # must not raise

    assert f'name="{pr_key(9)}"' in render_pr(
        {"number": 9, "title": "t", "gates": {}, "changes": []}, "o/r", False, False, "merge"
    )
    merge_pr = {"number": 9, "title": "t", "gates": {}, "changes": [ok_change]}
    out = render_pr(merge_pr, "o/r", False, False, "merge")
    assert merge_pr["review_body"] == "📝\n\n| なにがおきるか | 影響 | 内容 |\n| --- | --- | --- |\n| t | なし | i |" + footer
    assert "<pre>" in out and html.escape(merge_pr["review_body"]) in out

    delegate_pr = {"number": 10, "title": "t", "gates": {}, "changes": []}
    render_pr(delegate_pr, "o/r", False, False, "delegate")
    assert "review_body" not in delegate_pr

    try:
        render_pr({"number": 11, "title": "t", "gates": {}, "changes": [warn_change]}, "o/r", False, False, "merge")
        assert False, "a blocked PR in a merge group should be rejected"
    except SystemExit:
        pass

    # has_scope toggles the gutter on/off
    scoped = render_pr({"number": 1, "scope": "api", "title": "t", "gates": {}, "changes": []}, "o/r", False, True, "hold")
    assert '<span class="scope">api</span>' in scoped
    flat = render_pr({"number": 1, "title": "t", "gates": {}, "changes": []}, "o/r", False, False, "hold")
    assert "gutter" not in flat

    try:
        render_proposal({"title": "t", "target": {"repo": "o/r"}, "risks": [{"level": "ok", "text": "x"}]}, 1)
        assert False, "missing target.why should be rejected"
    except SystemExit:
        pass
    try:
        render_proposal({"title": "t", "target": {"repo": "o/r", "why": "w"}, "risks": []}, 1)
        assert False, "missing risks should be rejected"
    except SystemExit:
        pass
    prop = render_proposal(
        {
            "title": "t",
            "target": {"repo": "acme/config", "shared": True, "why": "w"},
            "diff": "-old\n+new",
            "risks": [{"level": "warn", "text": "r", "evidence": "$ cmd"}],
            "on_approve": "do it",
        },
        1,
    )
    assert f'name="{prop_key(1)}"' in prop
    assert '<span class="m">-old</span>' in prop and '<span class="p">+new</span>' in prop
    assert 'title="$ cmd"' in prop

    full = render(
        {
            "title": "T",
            "repo": "o/r",
            "public": False,
            "groups": [
                {
                    "verdict": "merge",
                    "title": "直接マージ",
                    "prs": [{"number": 118, "title": "t", "gates": {}, "changes": [ok_change]}],
                },
                {
                    "verdict": "delegate",
                    "title": "委任",
                    "prs": [{"number": 119, "title": "t2", "gates": {}, "changes": [warn_change]}],
                },
            ],
            "proposals": [
                {
                    "title": "p",
                    "target": {"repo": "o/r", "why": "w"},
                    "risks": [{"level": "ok", "text": "r"}],
                    "on_approve": "a",
                }
            ],
        },
        "12345/tok",
    )
    assert "#118" in full and "#119" in full and f'name="{prop_key(1)}"' in full
    assert "__" not in full  # no leftover template tokens

    # review_body must not be settable from the input
    try:
        render(
            {
                "repo": "o/r",
                "public": False,
                "groups": [{"verdict": "hold", "title": "g", "prs": [{"number": 1, "title": "t", "review_body": "x"}]}],
            },
            "1/t",
        )
        assert False, "review_body in the input should be rejected"
    except SystemExit:
        pass

    # render() must mutate pr["review_body"] before act_on_approvals() posts it --
    # that coupling is what makes "reviewed = what happens" true, so it needs its
    # own regression check instead of relying on a hand-authored review_body fixture.
    render_data = {
        "repo": "o/r",
        "public": False,
        "groups": [
            {
                "verdict": "merge",
                "title": "直接マージ",
                "prs": [{"number": 42, "title": "t", "gates": {}, "changes": [ok_change]}],
            }
        ],
    }
    render(render_data, "1/t")
    rendered_pr = render_data["groups"][0]["prs"][0]
    assert rendered_pr["review_body"] == gen_review_body([ok_change], public=False)

    posted = []

    def fake_post(cmd, **kw):
        posted.append((cmd, kw.get("input")))
        return subprocess.CompletedProcess(cmd, 0)

    real_run = subprocess.run
    subprocess.run = fake_post
    try:
        act_on_approvals(render_data, {pr_key(42): "approve"}, Path(tempfile.mkdtemp()) / "t.done.json")
    finally:
        subprocess.run = real_run
    review_calls = [(cmd, stdin) for cmd, stdin in posted if cmd[2] == "review"]
    assert len(review_calls) == 1, posted
    review_cmd, review_stdin = review_calls[0]
    assert review_cmd[2] == "review" and review_cmd[6:] == ["--approve", "--body-file", "-"], review_cmd
    assert review_stdin == rendered_pr["review_body"]

    calls = []
    data = {
        "repo": "o/r",
        "groups": [
            {
                "verdict": "merge",
                "prs": [
                    {"number": 1, "review_body": "b1"},  # reviewed, then merged
                    {"number": 2, "review_body": "b2"},  # denied
                    {"number": 3},  # merged without a review
                    {"number": 4, "review_body": "b4"},  # already done
                ],
            },
            {"verdict": "hold", "prs": [{"number": 5}]},  # approved, but not to merge
        ],
    }
    result = {pr_key(n): "deny" if n == 2 else "approve" for n in (1, 2, 3, 4, 5)}
    done = Path(tempfile.mkdtemp()) / "t.done.json"
    done.write_text('["4:merge", "4:review"]')
    real_run = subprocess.run

    def fake(cmd, **kw):
        calls.append(cmd)
        # #1 posts its review, then fails to arm the merge.
        return subprocess.CompletedProcess(cmd, 1 if cmd[2:4] == ["merge", "1"] else 0, stderr="x")

    subprocess.run = fake
    try:
        act_on_approvals(data, result, done)
        assert [(c[2], c[3]) for c in calls] == [
            ("review", "1"),
            ("merge", "1"),
            ("merge", "3"),
        ], calls
        assert json.loads(done.read_text()) == ["1:review", "3:merge", "4:merge", "4:review"]
        # Retrying must not repost #1's review just because its merge failed.
        calls.clear()
        act_on_approvals(data, result, done)
        assert [(c[2], c[3]) for c in calls] == [("merge", "1")], calls
    finally:
        subprocess.run = real_run

    # An auto-merge GitHub refuses because the PR is already mergeable falls
    # back to a plain merge, recorded under the same `done` key.
    calls.clear()
    clean_data = {"repo": "o/r", "groups": [{"verdict": "merge", "prs": [{"number": 6}]}]}
    done = Path(tempfile.mkdtemp()) / "t.done.json"

    def fake_clean(cmd, **kw):
        calls.append(cmd)
        if "--auto" in cmd:
            stderr = "GraphQL: Pull request Pull request is in clean status (enablePullRequestAutoMerge)"
            return subprocess.CompletedProcess(cmd, 1, stderr=stderr)
        return subprocess.CompletedProcess(cmd, 0, stderr="")

    subprocess.run = fake_clean
    real_stdout, sys.stdout = sys.stdout, io.StringIO()
    try:
        act_on_approvals(clean_data, {pr_key(6): "approve"}, done)
    finally:
        subprocess.run = real_run
        out, sys.stdout = sys.stdout.getvalue(), real_stdout
    assert [c[6:] for c in calls] == [["--squash", "--auto"], ["--squash"]], calls
    assert json.loads(done.read_text()) == ["6:merge"]
    # A merge that did happen must not be reported as FAILED: the caller reads
    # that as "not merged" and goes looking for a cause that isn't there.
    assert out.splitlines() == ["ok #6 merge"], out

    # Any other merge failure stays a failure -- never merge past an unmet gate.
    calls.clear()

    def fake_blocked(cmd, **kw):
        calls.append(cmd)
        return subprocess.CompletedProcess(cmd, 1, stderr="Pull request is not mergeable")

    subprocess.run = fake_blocked
    try:
        act_on_approvals(clean_data, {pr_key(6): "approve"}, Path(tempfile.mkdtemp()) / "t.done.json")
    finally:
        subprocess.run = real_run
    assert [c[6:] for c in calls] == [["--squash", "--auto"]], calls

    print("ok")
