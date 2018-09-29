#!/bin/bash

set -e

abspath() {
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

cd "$(dirname "$0")"

cat .symlinks | grep -v '^$' | while read link; do
  read from to <<< $link
  to="$(eval echo "$to")"
  to_dir="$(dirname "$to")"
  [ ! -d "$to_dir" ] && mkdir -p "$to_dir"
  from="$(abspath "$from")"
  to="$(abspath "$to")"
  ln -snfv "$from" "$to"
done
