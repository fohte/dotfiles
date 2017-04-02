#!/bin/bash

set -e

abspath() {
  echo "$(cd $(dirname $1) && pwd)/$(basename $1)"
}

cat .symlinks | grep -v '^$' | while read link; do
  read from to <<< $link
  to=$(eval echo $to)
  [ ! -d $to ] && mkdir -p "$(dirname "$to")"
  from=$(abspath $from)
  to=$(abspath $to)
  ln -sfnv $from $to
done
