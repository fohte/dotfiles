local convert(from, to) = {
  type: 'basic',
  from: {
    simultaneous: std.map(function(key_code) { key_code: key_code }, from),
  },
  to: std.map(function(key_code) { key_code: key_code }, to),
  conditions: [{
    type: 'input_source_if',
    input_sources: [{ language: 'ja' }],
  }],
};


local bulkConvert(pair) = std.map(function(pair) convert(pair[0], pair[1]), pair);

local shiins = [
  ['c', 'k'],
  ['k', 'k'],
  ['s', 's'],
  ['t', 't'],
  ['n', 'n'],
  ['h', 'h'],
  ['m', 'm'],
  ['y', 'y'],
  ['r', 'r'],
  ['w', 'w'],
  ['g', 'g'],
  ['z', 'z'],
  ['d', 'd'],
  ['b', 'b'],
  ['p', 'p'],
];

local abbrevs = [
  ["'", 'ai'],
  [',', 'ou'],
  ['.', 'ei'],
  [';', 'ann'],
  ['q', 'onn'],
  ['j', 'enn'],
  ['k', 'unn'],
  ['x', 'inn'],
];

local pairs = std.flatMap(
  function(abbrev)
    std.map(function(shiin) [shiin[0] + abbrev[0], shiin[1] + abbrev[1]], shiins),
  abbrevs
);

local manipulators = bulkConvert(pairs);

{
  title: 'DvorakJP',
  rules: [
    {
      description: 'DvorakJP (rev: %s)' % std.md5(std.toString(manipulators)),
      manipulators: manipulators,
    },
  ],
}
