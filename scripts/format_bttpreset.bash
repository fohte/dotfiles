set -euo pipefail

# this script will format a BetterTouchTool preset file to be more readable.
# usage: format_bttpreset.bash <file>

if [ $# -eq 0 ]; then
  echo "No input file specified"
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "File not found: $1"
  exit 1
fi

# create a temporary file
tmpfile="$(mktemp /tmp/bttpreset.XXXXXX)"

# sort randomly ordered arrays to make consistent
jq '
  .BTTPresetContent |= sort_by(.BTTAppBundleIdentifier)
   | .BTTPresetContent[].BTTTriggers |= sort_by(.BTTOrder, .BTTTriggerType, .BTTPredefinedActionType)
' "$1" > "$tmpfile"

mv "$tmpfile" "$1"
