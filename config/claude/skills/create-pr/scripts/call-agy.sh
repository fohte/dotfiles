# shellcheck shell=bash
# Sourced by agy-write-draft and agy-advance-draft. Not directly executable.

call_agy() {
  local prompt="$1" schema_file="$2" conversation_id="${3:-}"
  if [ -n "$conversation_id" ]; then
    agy -p "$prompt" --conversation "$conversation_id" --output-format json --json-schema "$schema_file"
  else
    agy -p "$prompt" --output-format json --json-schema "$schema_file"
  fi
}

agy_result_or_die() {
  local result="$1"
  local status
  status=$(jq -r '.status' <<< "$result")
  if [ "$status" != "SUCCESS" ]; then
    echo "Error: agy failed (status: $status)" >&2
    exit 1
  fi
}
