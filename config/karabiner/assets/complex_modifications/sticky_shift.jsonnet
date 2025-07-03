local manipulators = [
  {
    type: 'basic',
    from: {
      key_code: 'left_shift',
      modifiers: {
        // left_shift と任意の修飾キーの組み合わせを許可
        optional: [
          'any',
        ],
      },
    },
    parameters: {
      // 100 ms 以上押し続けた場合はホールドとみなす
      'basic.to_if_held_down_threshold_milliseconds': 100,
    },
    to: [
      {
        key_code: 'left_shift',
        // タップかホールドかが確定するまでキーイベントを遅延
        lazy: true,
      },
    ],
    // ホールド時は通常の L-Shift として動作
    to_if_held_down: [
      {
        key_code: 'left_shift',
      },
    ],
    // L-Ctrl 単押し時は Ctrl-, (AquaSKK の sticky key) を送信
    to_if_alone: [
      {
        modifiers: ['left_control'],
        key_code: 'comma',
      },
    ],
    conditions: [
      // IME が有効な場合のみに適用
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
