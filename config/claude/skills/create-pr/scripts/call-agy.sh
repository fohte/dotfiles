# shellcheck shell=bash
# Sourced by agy-write-draft and agy-advance-draft. Not directly executable.

call_agy() {
  local prompt="$1" schema_file="$2" conversation_id="${3:-}"
  if [ -n "$conversation_id" ]; then
    agy --print="$prompt" --conversation "$conversation_id" --output-format json --json-schema "$schema_file"
  else
    agy --print="$prompt" --output-format json --json-schema "$schema_file"
  fi
}

# A tool denied by the permission rules in config/agy leaves `status` at ERROR
# even though the draft itself was produced, so the schema-checked payload is the
# only signal separating a finished run from a failed one.
agy_result_or_die() {
  local result="$1"
  if ! jq -e '.structured_output != null' <<< "$result" > /dev/null; then
    echo "Error: agy failed (status: $(jq -r '.status' <<< "$result"))" >&2
    exit 1
  fi
}
