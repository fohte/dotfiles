local aquaskk_re = '^jp\\.sourceforge\\.inputmethod\\.aquaskk$';

local manipulate(from, to, is_skk) = {
  type: 'basic',
  from: {
    key_code: from,
    modifiers: { optional: ['any'] },
  },
  parameters: {
    'basic.to_if_held_down_threshold_milliseconds': 100,
  },
  to: [{ key_code: from, lazy: true }],
  to_if_held_down: [{ key_code: from }],
  to_if_alone: [to],

  conditions: [
    (if is_skk then {
       type: 'input_source_if',
     } else {
       type: 'input_source_unless',
     }) + {
      input_sources: [{ input_source_id: aquaskk_re }],
    },
  ],
};

local manipulators =
  [
    // [on AquaSKK] Left/Right Command -> Ctrl+q/Ctrl+t
    manipulate('left_command', { modifiers: ['left_control'], key_code: 'q' }, true),
    manipulate('right_command', { modifiers: ['left_control'], key_code: 't' }, true),

    // [not on AquaSKK] Left/Right Command -> 英数/かな
    manipulate('left_command', { key_code: 'japanese_eisuu' }, false),
    manipulate('right_command', { key_code: 'japanese_kana' }, false),

    // [on AquaSKK] Left/Right Option -> Ctrl+q/Ctrl+t
    manipulate('left_option', { modifiers: ['left_control'], key_code: 'q' }, true),
    manipulate('right_option', { modifiers: ['left_control'], key_code: 't' }, true),

    // [not on AquaSKK] Left/Right Option -> 英数/かな
    manipulate('left_option', { key_code: 'japanese_eisuu' }, false),
    manipulate('right_option', { key_code: 'japanese_kana' }, false),

  ];


{
  title: '英数/かな',
  rules: [{
    description: 'Left/Right Command/Option -> 英数/かな (rev: %s)' % std.md5(std.toString(manipulators)),
    manipulators: manipulators,
  }],
}
