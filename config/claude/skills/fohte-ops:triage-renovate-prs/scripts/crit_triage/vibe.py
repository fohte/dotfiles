"""Vibe authorization gate for actions that bypass crit approval."""
import json
import os
import subprocess


NOT_ENABLED = {"Vibe mode is not enabled.", "Error: Vibe mode is not enabled."}


def _output(result):
    return "\n".join(part.strip() for part in (result.stdout, result.stderr) if part and part.strip()).strip()


def _agent_vibe_status():
    command = ["a", "agent", "vibe", "status"]
    for attempt in range(2):
        result = subprocess.run(command, text=True, capture_output=True)
        if result.returncode == 0:
            return True
        output = _output(result)
        if output in NOT_ENABLED:
            return False
        if attempt == 1:
            raise SystemExit(f"could not determine session vibe status: {output or result.returncode}")
    return False


def _repo_vibe_setting():
    command = ["a", "config", "get", "repo.vibe"]
    for attempt in range(2):
        result = subprocess.run(command, text=True, capture_output=True)
        if result.returncode == 0:
            try:
                value = json.loads(result.stdout)
            except json.JSONDecodeError:
                value = None
            if isinstance(value, bool):
                return value
            output = f"expected a boolean from {' '.join(command)}, got: {_output(result)!r}"
        else:
            output = _output(result) or str(result.returncode)
        if attempt == 1:
            raise SystemExit(f"could not determine repository vibe setting: {output}")
    return False


def check_vibe_mode():
    """Return true only when both session and repository vibe gates are enabled."""
    if not _agent_vibe_status():
        return False
    return _repo_vibe_setting()


def require_vibe_mode(expected_repo):
    if not check_vibe_mode():
        raise SystemExit("--vibe-approve requires vibe mode to be enabled for this session and repository")

    # GH_REPO can redirect gh away from the checkout whose local policy was checked.
    gh_env = os.environ.copy()
    gh_env.pop("GH_REPO", None)
    result = subprocess.run(
        ["gh", "repo", "view", "--json", "nameWithOwner"],
        text=True,
        capture_output=True,
        env=gh_env,
    )
    if result.returncode != 0:
        detail = _output(result) or str(result.returncode)
        raise SystemExit(f"could not determine the current GitHub repository: {detail}")
    try:
        payload = json.loads(result.stdout)
        current_repo = payload["nameWithOwner"]
    except (json.JSONDecodeError, KeyError, TypeError):
        raise SystemExit(f"could not read nameWithOwner from gh repo view: {_output(result)!r}")

    expected = str(expected_repo).strip()
    if not isinstance(current_repo, str) or not expected or current_repo.casefold() != expected.casefold():
        raise SystemExit(
            f"--vibe-approve data repo {expected!r} does not match current GitHub repository {current_repo!r}"
        )
