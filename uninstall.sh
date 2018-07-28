#!/bin/bash

set -e

abspath() {
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

cat .symlinks | grep -v '^$' | while read link; do
  read from to <<< $link
  to="$(eval abspath "$to")"
  [ -e "$to" ] && unlink "$to" && echo unlink "$to"
done
