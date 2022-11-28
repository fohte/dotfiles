import re

from xkeysnail.transform import *

define_multipurpose_modmap({
    Key.LEFT_ALT: [Key.MUHENKAN, Key.LEFT_ALT],
    Key.RIGHT_ALT: [Key.HIRAGANA, Key.RIGHT_ALT],
})


def change_modifier_keys(before_mod, after_mod, keys):
    return {K(f'{before_mod}-{key}'): K(f'{after_mod}-{key}') for key in keys}


def super_to(modifier, keys):
    return change_modifier_keys('Super', modifier, keys)


def super_shift_to(modifier, keys):
    return change_modifier_keys('Super-Shift', modifier, keys)


def super_to_ctrl(keys):
    return super_to('C', keys)


def super_shift_to_ctrl_shift(keys):
    return super_shift_to('C-Shift', keys)


terminals = ('URxvt', 'kitty', 'Alacritty')

define_keymap(
    lambda wm_class: wm_class not in terminals,
    {
        K("M-backspace"): with_mark(K("C-backspace")),

        # Cursor
        K("C-b"): with_mark(K("left")),
        K("C-f"): with_mark(K("right")),
        K("C-p"): with_mark(K("up")),
        K("C-n"): with_mark(K("down")),
        K("C-h"): with_mark(K("backspace")),
        # Forward/Backward word
        K("M-b"): with_mark(K("C-left")),
        K("M-left"): with_mark(K("C-left")),
        K("M-f"): with_mark(K("C-right")),
        K("M-right"): with_mark(K("C-right")),
        # Beginning/End of line
        K("C-a"): with_mark(K("home")),
        K("C-e"): with_mark(K("end")),
        # Page up/down
        K("M-v"): with_mark(K("page_up")),
        K("C-u"): with_mark(K("page_up")),
        K("C-v"): with_mark(K("page_down")),
        K("C-d"): with_mark(K("page_down")),
        # Beginning/End of file
        K("M-Shift-comma"): with_mark(K("C-home")),
        K("M-Shift-dot"): with_mark(K("C-end")),
        # Delete
        K("M-d"): [K("C-delete"), set_mark(False)],
        # Kill line
        K("C-k"): [K("Shift-end"), K("C-x"),
                   set_mark(False)],
        **super_to_ctrl([
            'a',
            'c',
            'e',
            'f',
            'l',
            'n',
            'r',
            't',
            'v',
            'w',
            'x',
            'z',
        ]),
        **super_shift_to_ctrl_shift([
            'n',
            't',
        ]),
    })

define_keymap(lambda wm_class: wm_class in terminals, {
    **super_to('C-Shift', ['c', 'v']),
})
