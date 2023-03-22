local convert(from, to, mandatory=null) = {
  type: 'basic',
  from: {
    key_code: from,
    modifiers: {
      optional: [
        'caps_lock',
        'left_command',
        'left_control',
        'left_option',
        'right_command',
        'right_control',
        'right_option',
      ],
      [if mandatory != null then 'mandatory']: [mandatory],
    },
  },
  to: [
    {
      key_code: to,
      [if mandatory != null then 'modifiers']: [mandatory],
    },
  ],
  conditions: [{
    type: 'device_if',
    identifiers: [
      {
        vendor_id: 1452,
        product_id: 641,
        description: 'Apple Internal Keyboard',
      },
      {
        vendor_id: 1452,
        product_id: 834,
        description: 'Apple Internal Keyboard',
      },
    ],
  }],
};

local transformValues(func, obj) = std.map(
  function(x) func(x, obj[x]),
  std.objectFields(obj)
);

local bulkConvert(pair) = std.flatMap(
  function(mandatory) std.map(
    function(pair) convert(pair[0], pair[1], mandatory),
    pair
  ),
  [null, 'left_shift', 'right_shift']
);

local manipulators = bulkConvert([
  ['grave_accent_and_tilde', 'grave_accent_and_tilde'],
  ['1', '1'],
  ['2', '2'],
  ['4', '4'],
  ['5', '5'],
  ['6', '6'],
  ['7', '7'],
  ['8', '8'],
  ['9', '9'],
  ['0', '0'],
  ['hyphen', 'open_bracket'],
  ['equal_sign', 'close_bracket'],
  ['q', 'quote'],
  ['w', 'comma'],
  ['e', 'period'],
  ['r', 'p'],
  ['t', 'y'],
  ['y', 'f'],
  ['u', 'g'],
  ['i', 'c'],
  ['o', 'r'],
  ['p', 'l'],
  ['open_bracket', 'slash'],
  ['close_bracket', 'equal_sign'],
  ['backslash', 'backslash'],
  ['a', 'a'],
  ['s', 'o'],
  ['d', 'e'],
  ['f', 'u'],
  ['g', 'i'],
  ['h', 'd'],
  ['j', 'h'],
  ['k', 't'],
  ['l', 'n'],
  ['semicolon', 's'],
  ['quote', 'hyphen'],
  ['z', 'semicolon'],
  ['x', 'q'],
  ['c', 'j'],
  ['v', 'k'],
  ['b', 'x'],
  ['n', 'b'],
  ['m', 'm'],
  ['comma', 'w'],
  ['period', 'v'],
  ['slash', 'z'],
]);

{
  title: 'Dvorak Keyboard',
  rules: [
    {
      description: 'Remap keys to use Dvorak keyboard layout (rev: %s)' % std.md5(std.toString(manipulators)),
      manipulators: manipulators,
    },
  ],
}
