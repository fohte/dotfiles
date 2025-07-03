local manipulators = [
  {
    type: 'basic',
    from: {
      key_code: 'left_shift',
      modifiers: {
        optional: [
          'any',
        ],
      },
    },
    parameters: {
      'basic.to_if_held_down_threshold_milliseconds': 100,
    },
    to: [
      {
        key_code: 'left_shift',
        lazy: true,
      },
    ],
    to_if_held_down: [
      {
        key_code: 'left_shift',
      },
    ],
    to_if_alone: [
      {
        modifiers: ['left_control'],
        key_code: 'comma',
      },
    ],
    conditions: [
      {
        type: 'input_source_if',
        input_sources: [
          {
            language: 'ja',
          },
        ],
      },
    ],
  },
];

{
  title: 'Sticky Shift',
  rules: [
    {
      description: 'Left Shift キーを単体で押したときに Ctrl-, (sticky key) を送信する (rev: %s)' % std.md5(std.toString(manipulators)),
      manipulators: manipulators,
    },
  ],
}
