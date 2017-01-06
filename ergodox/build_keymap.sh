#!/bin/bash

KEYMAP=fohte
KEYBOARD=ergodox
SUB=ez

cd $(dirname $0)
pwd_dir=$(pwd)

QMK_DIR="$pwd_dir/qmk"
MY_KEYMAP_DIR="$pwd_dir/src"
QMK_KEYMAP_DIR="${QMK_DIR}/keyboards/ergodox/keymaps/${KEYMAP}"

HEX_FILE="${KEYBOARD}_${SUB}_${KEYMAP}.hex"

[ ! -e "$QMK_DIR" ] && git clone https://github.com/fohte/qmk_firmware.git "$QMK_DIR"
rm -rf "$QMK_KEYMAP_DIR"
cp -rf "$MY_KEYMAP_DIR" "$QMK_KEYMAP_DIR"

docker run --rm -e keymap=$KEYMAP -e keyboard=$KEYBOARD -v "$QMK_DIR":/qmk:rw -t jackhumbert/qmk_firmware /bin/bash -c 'make' || exit 1
cp -f "$QMK_DIR/$HEX_FILE" "$pwd_dir/$HEX_FILE" && echo "Created hex file: $pwd_dir/$HEX_FILE"
