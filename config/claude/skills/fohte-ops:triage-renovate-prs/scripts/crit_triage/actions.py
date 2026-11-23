"""GitHub review and merge actions for the human-reviewed report."""
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
            steps = []
            if pr.get("review_body"):
                steps.append((["review", "--approve", "--body-file", "-"], pr["review_body"]))
            # `--auto` hands the CI gate to GitHub, which merges once the required
            # checks pass -- including after a Renovate rebase, since only a push
            # from someone without write access disarms it.
            steps.append((["merge", "--squash", "--auto"], None))
            for argv, stdin in steps:
                # The deny loop re-runs this script against the same data file,
                # and one step can fail after an earlier one landed, so each is
                # recorded on its own rather than per PR.
                key = f"{num}:{argv[0]}"
                if key in done:
                    print(f"skip #{num} {argv[0]}: already done")
                    continue
                run = gh_pr(data["repo"], num, argv, stdin)
                # GitHub refuses to arm auto-merge on an already mergeable PR.
                if run.returncode != 0 and "--auto" in argv and "clean status" in (run.stderr or ""):
                    run = gh_pr(data["repo"], num, [a for a in argv if a != "--auto"], stdin)
                ok = run.returncode == 0
                # One line per step, printed only once the step is settled:
                # readers take `FAILED` to mean the operation did not happen.
                print(f"{'ok' if ok else 'FAILED'} #{num} {argv[0]}" + ("" if ok else f": {(run.stderr or '').strip()}"))
                if not ok:
                    # Never arm a merge on a PR whose approving review failed to
                    # post; branch protection would block it anyway.
                    break
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
            key = f"{num}:review"
            if key in done:
                print(f"skip #{num} review: already done")
                continue
            run = gh_pr(data["repo"], num, ["review", "--approve", "--body-file", "-"], pr["review_body"])
            ok = run.returncode == 0
            print(f"{'ok' if ok else 'FAILED'} #{num} review" + ("" if ok else f": {(run.stderr or '').strip()}"))
            if not ok:
                failed = True
                continue
            done.add(key)
            done_path.write_text(json.dumps(sorted(done)))
    return not failed
