// local convert(from, to) = {
//   type: 'basic',
//   from: {
//     // simultaneous: std.map(function(key_code) { key_code: key_code }, from),
//
//   },
//   to: std.map(function(key_code) { key_code: key_code }, to),
//   conditions: [{
//     type: 'input_source_if',
//     input_sources: [{ language: 'ja' }],
//   }],
// };

local shiins = [
  'k',
  's',
  't',
  'n',
  'h',
  'm',
  'y',
  'r',
  'w',
  'g',
  'z',
  'd',
  'b',
  'p',
];

local abbrevs = [
  ['quote', 'ai'],
  ['comma', 'ou'],
  ['period', 'ei'],
  ['semicolon', 'ann'],
  ['q', 'onn'],
  ['j', 'enn'],
  ['k', 'unn'],
  ['x', 'inn'],
];

local pairs = std.flatMap(function(shiin) [
  {
    type: 'basic',
    from: { key_code: shiin },
    to: [
      { key_code: shiin },
      { set_variable: { name: 'dvorakjp_prev_key', value: shiin } },
    ],
    to_delayed_action: {
      to_if_invoked: [{ set_variable: { name: 'dvorakjp_prev_key', value: '' } }],
    },
    conditions: [
      { type: 'input_source_if', input_sources: [{ language: 'ja' }] },
    ],
  },
] + std.map(function(abbrev) {
  type: 'basic',
  from: { key_code: abbrev[0] },
  to: std.map(function(after) { key_code: after }, abbrev[1]) + [
    { set_variable: { name: 'dvorakjp_prev_key', value: '' } },
  ],
  conditions: [
    { type: 'input_source_if', input_sources: [{ language: 'ja' }] },
    { type: 'variable_if', name: 'dvorakjp_prev_key', value: shiin },
  ],
}, abbrevs), shiins);

local ys = std.flatMap(function(from) [
  {
    type: 'basic',
    from: { key_code: from },
    to: [
      { key_code: from },
      { set_variable: { name: 'dvorakjp_prev_key', value: from } },
    ],
    to_delayed_action: {
      to_if_invoked: [{ set_variable: { name: 'dvorakjp_prev_key', value: '' } }],
    },
    conditions: [
      { type: 'input_source_if', input_sources: [{ language: 'ja' }] },
    ],
  },
  {
    type: 'basic',
    from: { key_code: 'n' },
    to: [
      { key_code: 'n' },
      { set_variable: { name: 'dvorakjp_prev_key', value: 'n' } },
    ],
  },
], [
  'k',
  's',
  't',
  'n',
  'h',
  'm',
  'r',
  'g',
  'z',
  'd',
  'b',
  'p',
]);

// local pairs = [
//   // {
//   //   type: 'basic',
//   //   from: { key_code: 't' },
//   //   to: [
//   //     { key_code: 't' },
//   //     { set_variable: { name: 'dvorakjp_prev_key', value: 't' } },
//   //   ],
//   //   to_if_alone: [
//   //     { set_variable: { name: 'dvorakjp_prev_key', value: '' } },
//   //   ],
//   //   conditions: [
//   //     { type: 'input_source_if', input_sources: [{ language: 'ja' }] },
//   //   ],
//   // },
//   {
//     type: 'basic',
//     from: { key_code: 'quote' },
//     to: [
//       { key_code: 'a' },
//       { key_code: 'i' },
//       { set_variable: { name: 'dvorakjp_prev_key', value: '' } },
//     ],
//     conditions: [
//       { type: 'input_source_if', input_sources: [{ language: 'ja' }] },
//       { type: 'variable_if', name: 'dvorakjp_prev_key', value: 't' },
//     ],
//   },
// ];


// local bulkConvert(pair) = std.flatMap(function(pair) convert(pair[0], pair[1]), pair);

// local pairs = std.flatMap(
//   function(abbrev)
//     std.map(function(shiin) [shiin[0] + abbrev[0], shiin[1] + abbrev[1]], shiins),
//   abbrevs
// );

local remappings = std.map(function(pair) {
  type: 'basic',
  from: std.map(function(c) { key_code: c }, pair[0]),
  to: std.map(function(c) { key_code: c }, pair[1]),
  conditions: [
    { type: 'input_source_if', input_sources: [{ language: 'ja' }] },
  ],
}, [
  ['c', 'k'],
  ['kn', 'ky'],
  ['sn', 'sy'],
  ['tn', 'ty'],
  ['nn', 'ny'],
  ['hn', 'hy'],
  ['mn', 'my'],
  ['yn', 'yy'],
  ['rn', 'ry'],
  ['wn', 'wy'],
  ['gn', 'gy'],
  ['zn', 'zy'],
  ['dn', 'dy'],
  ['bn', 'by'],
  ['pn', 'py'],
]);

// local manipulators = [cToK] + bulkConvert(pairs);
local manipulators = remappings + pairs;

{
  title: 'DvorakJP',
  rules: [
    {
      description: 'DvorakJP (rev: %s)' % std.md5(std.toString(manipulators)),
      manipulators: manipulators,
    },
  ],
}
