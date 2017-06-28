#!/bin/bash

set -e

KEYMAP=fohte
KEYBOARD=ergodox
SUB=ez

cd $(dirname $0)
pwd_dir=$(pwd)

QMK_DIR="$pwd_dir/qmk_firmware"
MY_KEYMAP_DIR="$pwd_dir/src"
QMK_KEYMAP_DIR="${QMK_DIR}/keyboards/ergodox/keymaps/${KEYMAP}"

HEX_FILE="${KEYBOARD}_${SUB}_${KEYMAP}.hex"

if [ ! -e "$QMK_DIR" ]; then
  git submodule update --init --recursive
  exit 1
fi

rm -rf "$QMK_KEYMAP_DIR"
cp -rf "$MY_KEYMAP_DIR" "$QMK_KEYMAP_DIR"

docker run --rm -e keymap=$KEYMAP -e keyboard=$KEYBOARD -v "$QMK_DIR":/qmk:rw -t jackhumbert/qmk_firmware /bin/bash -c 'make' || exit 1
cp -f "$QMK_DIR/$HEX_FILE" "$pwd_dir/$HEX_FILE" && echo "Created hex file: $pwd_dir/$HEX_FILE"

rm -f "$QMK_DIR/$HEX_FILE"
rm -rf $QMK_KEYMAP_DIR
