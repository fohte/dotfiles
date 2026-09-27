# shellcheck shell=bash
# Sourced by agy-write-draft and agy-advance-draft. Not directly executable.

call_agy() {
  local prompt="$1" schema_file="$2"
  # The default high tier's per-turn thinking cost overruns agy's 5m print
  # deadline.
  agy --print="$prompt" --model gemini-3.8-flash-low --output-format json --json-schema "$schema_file"
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

writing_rules() {
  local purpose
  purpose=$(git config --get "branch.$(git branch --show-current).x-purpose" || true)
  "$(dirname "${BASH_SOURCE[0]}")/render-rules" "$purpose" || return
  [ -z "$purpose" ] || printf '\n<branch_purpose>\n%s\n</branch_purpose>\n' "$purpose"
}

instruction_block() {
  [ -n "$1" ] || return 0
  printf '\n<additional_instructions>\n%s\n</additional_instructions>\n' "$1"
}

# Records what agy last wrote so agy-advance-draft can tell whether the user
# has commented since.
save_agy_output() {
  local draft_path="$1" title="$2" body="$3"
  printf '%s\n%s' "$title" "$body" > "${draft_path}.agy-output"
}

agy_output_unchanged() {
  local draft_path="$1" title="$2" body="$3"
  [ -f "${draft_path}.agy-output" ] \
    && [ "$(cat "${draft_path}.agy-output")" = "$(printf '%s\n%s' "$title" "$body")" ]
}
