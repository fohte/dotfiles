#!/bin/bash

set -e

abspath() {
  echo "$(cd $(dirname $1) && pwd)/$(basename $1)"
}

cat .symlinks | grep -v '^$' | while read link; do
  read from to <<< $link
  from=$(abspath $from)
  to=$(eval abspath $to)
  ln -sfnv $from $to
done
