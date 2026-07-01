# Populate GITHUB_TOKEN from gh's keyring so tools like pinact / act avoid the
# unauthenticated API rate limit.
if [ -z "$GITHUB_TOKEN" ] && command -v gh > /dev/null 2>&1; then
  _github_token="$(gh auth token 2> /dev/null)"
  [ -n "$_github_token" ] && export GITHUB_TOKEN="$_github_token"
  unset _github_token
fi
