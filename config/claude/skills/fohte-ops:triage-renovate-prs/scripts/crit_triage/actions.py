"""GitHub review and merge actions for triage reports."""
import json
import subprocess
from pathlib import Path

from .report import pr_key


def gh_pr(repo, num, argv, stdin=None):
    """Run one `gh pr <verb>` against a PR."""
    return subprocess.run(
        ["gh", "pr", argv[0], str(num), "-R", repo, *argv[1:]],
        input=stdin,
        text=True,
        capture_output=True,
    )


def post_review(repo, num, body, done, done_path, key, expected_head=None):
    if expected_head:
        head = gh_pr(repo, num, ["view", "--json", "headRefOid", "--jq", ".headRefOid"])
        if head.returncode != 0:
            detail = (head.stderr or "").strip() or "could not read the current PR head"
            print(f"FAILED #{num} review: {detail}")
            return False
    if key in done:
        print(f"skip #{num} review: already done")
        return True
        if head.stdout.strip() != expected_head:
            detail = f"head changed from {expected_head} to {head.stdout.strip()}"
            print(f"FAILED #{num} review: {detail}")
            return False
    run = gh_pr(repo, num, ["review", "--approve", "--body-file", "-"], body)
    ok = run.returncode == 0
    print(f"{'ok' if ok else 'FAILED'} #{num} review" + ("" if ok else f": {(run.stderr or '').strip()}"))
    if ok:
        done.add(key)
        done_path.write_text(json.dumps(sorted(done)))
    return ok


def act_on_approvals(data, result, done_path):
    """Carry out what the human signed off on in the report, PR by PR.

    Proposals are never acted on here -- an approved proposal is only surfaced
    in the printed result for Claude to carry out afterwards.
    """
    done = set(json.loads(done_path.read_text())) if done_path.exists() else set()
    for group in data["groups"]:
        for pr in group["prs"]:
            num = pr["number"]
            if group["verdict"] != "merge" or result[pr_key(num)] != "approve":
                continue
            if pr.get("review_body"):
                if not post_review(
                    data["repo"], num, pr["review_body"], done, done_path, f"{num}:review"
                ):
                    continue
            # `--auto` hands the CI gate to GitHub, which merges once the required
            # checks pass -- including after a Renovate rebase, since only a push
            # from someone without write access disarms it.
            key = f"{num}:merge"
            if key in done:
                print(f"skip #{num} merge: already done")
                continue
            run = gh_pr(data["repo"], num, ["merge", "--squash", "--auto"])
            # GitHub refuses to arm auto-merge on an already mergeable PR.
            if run.returncode != 0 and "clean status" in (run.stderr or ""):
                run = gh_pr(data["repo"], num, ["merge", "--squash"])
            ok = run.returncode == 0
            print(f"{'ok' if ok else 'FAILED'} #{num} merge" + ("" if ok else f": {(run.stderr or '').strip()}"))
            if ok:
                done.add(key)
                done_path.write_text(json.dumps(sorted(done)))


def post_approve_reviews(data, done_path):
    """Post approve reviews for merge-verdict PRs without merging them."""
    done = set(json.loads(done_path.read_text())) if done_path.exists() else set()
    failed = False
    for group in data["groups"]:
        if group["verdict"] != "merge":
            continue
        for pr in group["prs"]:
            num = pr["number"]
            if not pr.get("review_body"):
                raise SystemExit(f"#{num}: approve review body was not generated")
            head_sha = pr.get("head_sha")
            if not head_sha:
                raise SystemExit(f"#{num}: head_sha is required for a vibe approve review")
            key = f"{num}:{head_sha}:review"
            posted = post_review(
                data["repo"], num, pr["review_body"], done, done_path, key, expected_head=head_sha
            )
            if not posted:
                failed = True
    return not failed
