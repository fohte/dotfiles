#!/bin/bash

KEYMAP=fohte
KEYBOARD=ergodox
SUB=ez

pwd_dir=$(dirname $0)
cd "$pwd_dir"

QMK_DIR="qmk"
MY_KEYMAP_C="keymap.c"
QMK_KEYMAP_DIR="${QMK_DIR}/keyboards/ergodox/keymaps/${KEYMAP}"
HEX_FILE="${KEYBOARD}_${SUB}_${KEYMAP}.hex"

[ ! -e "$QMK_DIR" ] && git clone https://github.com/fohte/qmk_firmware.git "$QMK_DIR"
mkdir -p "$QMK_KEYMAP_DIR"
cp -f "$MY_KEYMAP_C" "$QMK_KEYMAP_DIR/keymap.c"

docker run --rm -e keymap=$KEYMAP -e keyboard=$KEYBOARD -v "$('pwd')/$QMK_DIR":/qmk:rw -t jackhumbert/qmk_firmware /bin/bash -c 'make' || exit 1
cp -f "$QMK_DIR/$HEX_FILE" "$HEX_FILE" && echo "Created hex file: $pwd_dir/$HEX_FILE"
