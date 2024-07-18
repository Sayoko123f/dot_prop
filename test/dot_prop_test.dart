import 'package:test/test.dart';
import 'package:dot_prop/dot_prop.dart';

void main() {
  group('dot prop test', () {
    // This function will be called before each test is run.
    setUp(() {});

    test('basic', () async {
      const defaultValue = -1;
      final root = <String, dynamic>{};
      const key = 'foo.bar.abc';
      expect(getProperty(root, key, defaultValue), equals(defaultValue));
      setProperty(root, key, 1);
      expect(root['foo']['bar']['abc'], equals(1));
      expect(getProperty(root, key, defaultValue), equals(1));
    });

    test('getProperty', () {
      final fixture1 = {
        'foo': {'bar': 1},
        '': 'foo',
      };
      expect(getProperty(fixture1, ''), equals('foo'));
      expect(getProperty(fixture1, 'foo'), equals(fixture1['foo']));
      expect(getProperty({'foo': 1}, 'foo'), equals(1));
      expect(getProperty({'foo': null}, 'foo'), equals(null));
      expect(
          getProperty({
            'foo': {'bar': true}
          }, 'foo.bar'),
          equals(true));
      expect(
          getProperty({
            'foo': {
              'bar': {'baz': true}
            }
          }, 'foo.bar.baz'),
          equals(true));
      expect(
          getProperty({
            'foo': {
              'bar': {'baz': null}
            }
          }, 'foo.bar.baz'),
          equals(null));
      expect(
          getProperty({
            'foo': {'bar': 'a'}
          }, 'foo.fake'),
          equals(null));
      expect(
          getProperty({
            'foo': {'bar': 'a'}
          }, 'foo.fake.fake2'),
          equals(null));
      expect(
          getProperty({
            'foo': {'bar': 'a'}
          }, 'foo.fake.fake2', 'some value'),
          equals('some value'));
      expect(
          getProperty({'foo': <dynamic, dynamic>{}}, 'foo.fake', 'some value'),
          equals('some value'));
      expect(getProperty({'\\': true}, '\\'), equals(true));
      expect(getProperty({'\\foo': true}, '\\foo'), equals(true));
      expect(getProperty({'\\foo': true}, '\\\\foo'), equals(true));
      expect(getProperty({'foo\\': true}, 'foo\\\\'), equals(true));
      expect(getProperty({'bar\\': true}, 'bar\\'), equals(true));
      expect(getProperty({'foo\\bar': true}, 'foo\\bar'), equals(true));
      expect(
          getProperty({
            '\\': {'foo': true}
          }, '\\\\.foo'),
          equals(true));
      expect(getProperty({'bar\\.': true}, 'bar\\\\\\.'), equals(true));
      expect(
          getProperty({
            'foo\\': {'bar': true}
          }, 'foo\\\\.bar'),
          equals(true));
      expect(getProperty({'foo': 1}, 'foo.bar'), null);
      expect(getProperty({'foo\\': true}, 'foo\\'), true);

      expect(getProperty({'foo': 'bar'}, 'foo'), 'bar');

      final f3 = {'foo': null};
      expect(getProperty(f3, 'foo.bar'), null);
      expect(getProperty(f3, 'foo.bar', 'some value'), 'some value');

      expect(
          getProperty({
            'foo.baz': {'bar': true}
          }, 'foo\\.baz.bar'),
          true);
      expect(
          getProperty({
            'fo.ob.az': {'bar': true}
          }, 'fo\\.ob\\.az.bar'),
          true);

      expect(getProperty(null, 'foo.bar', false), false);
      expect(getProperty(0, 'foo.bar', false), false);
      expect(getProperty('foo', 'foo.bar', false), false);
      expect(getProperty(<dynamic>[], 'foo.bar', false), false);
      expect(getProperty(<dynamic, dynamic>{}, 'foo.bar', false), false);

      expect(
          getProperty({
            '': {'': true}
          }, '.'),
          true);
      expect(
          getProperty({
            '': {
              '': {'': true}
            }
          }, '..'),
          true);
    });

    test('getProperty - with array indexes', () {
      expect(getProperty([true, false, false], '[0]'), true);
      expect(
          getProperty([
            [false, true, false],
            false,
            false
          ], '[0][1]'),
          true);
      expect(
          getProperty([
            {
              'foo': [true]
            }
          ], '[0].foo[0]'),
          true);
      expect(
          getProperty({
            'foo': [
              0,
              {'bar': true}
            ]
          }, 'foo[1].bar'),
          true);

      expect(getProperty(['a', 'b', 'c'], '3', false), false);
      expect(
          getProperty([
            {
              'foo': [1]
            }
          ], '[0].bar[0]', false),
          false);
      expect(
          getProperty([
            {
              'foo': [1]
            }
          ], '[0].foo[1]', false),
          false);

      expect(
          getProperty({
            'foo': [
              0,
              {'bar': 2}
            ]
          }, 'foo[0].bar', false),
          false);
      expect(
          getProperty({
            'foo': [
              0,
              {'bar': 2}
            ]
          }, 'foo[2].bar', false),
          false);
      expect(
          getProperty({
            'foo': [
              0,
              {'bar': 2}
            ]
          }, 'foo[1].biz', false),
          false);
      expect(
          getProperty({
            'foo': [
              0,
              {'bar': 2}
            ]
          }, 'bar[0].bar', false),
          false);

      expect(
          getProperty({
            'bar': {
              '[0]': true,
            },
          }, 'bar.\\[0]'),
          true);
      expect(
          getProperty({
            'bar': {
              '': [true],
            },
          }, 'bar.[0]'),
          true);

      expect(
          () => getProperty({
                'foo[5[': true,
              }, 'foo[5['),
          _matchArgumentErrorMessage('Invalid character in an index'));
      expect(
          () => getProperty({
                'foo[5': {
                  'bar': true,
                },
              }, 'foo[5.bar'),
          _matchArgumentErrorMessage('Invalid character in an index'));
      expect(
          getProperty({
            'foo[5]': {
              'bar': true,
            },
          }, 'foo\\[5].bar'),
          true);
      expect(
          () => getProperty({
                'foo[5\\]': {
                  'bar': true,
                },
              }, 'foo[5\\].bar'),
          _matchArgumentErrorMessage('Invalid character in an index'));
      expect(
          () => getProperty({
                'foo[5': true,
              }, 'foo[5'),
          _matchArgumentErrorMessage('Index was not closed'));
      expect(
          () => getProperty({
                'foo[bar]': true,
              }, 'foo[bar]'),
          _matchArgumentErrorMessage('Invalid character in an index'));

      expect(getProperty(<dynamic, dynamic>{}, 'constructor[0]', false), false);
      expect(getProperty(<dynamic>[], 'foo[0].bar', false), false);
      expect(
          getProperty({
            'foo': [
              {'bar': true}
            ]
          }, 'foo[0].bar', false),
          true);
      expect(
          getProperty({
            'foo': ['bar']
          }, 'foo[1]', false),
          false);
      expect(getProperty([true], '0', false), false);
      expect(
          getProperty({
            'foo': [true]
          }, 'foo.0', false),
          false);
      expect(
          getProperty([
            {
              '[1]': true,
            },
            false,
            false
          ], '[0].\\[1]', false),
          true);
      expect(
          getProperty({
            'foo': {'[0]': true}
          }, 'foo.\\[0]'),
          true);

      expect(
          getProperty({
            'foo': {'[0]': true}
          }, 'foo.\\[0]', false),
          true);
      expect(
          () => getProperty({
                'foo': {'[0]': true}
              }, 'foo.[0\\]'),
          _matchArgumentErrorMessage('Invalid character in an index'));

      expect(
          getProperty({
            'foo': {
              '\\': [true]
            }
          }, 'foo.\\\\[0]'),
          true);
      expect(
          () => getProperty({
                'foo': {'[0]': true}
              }, 'foo.[0\\]'),
          _matchArgumentErrorMessage('Invalid character in an index'));

      expect(
          () => getProperty({
                'foo[0': {'9]': true}
              }, 'foo[0.9]'),
          _matchArgumentErrorMessage('Invalid character in an index'));
      expect(() => getProperty({'foo[-1]': true}, 'foo[-1]'),
          _matchArgumentErrorMessage('Invalid character in an index'));
    });

    test('setProperty', () {
      Map<String, dynamic> fixture1 = {};
      final o1 = setProperty(fixture1, 'foo', 2);
      expect(fixture1['foo'], 2);
      expect(o1, o1);

      fixture1 = {
        'foo': <String, dynamic>{'bar': 1}
      };
      setProperty(fixture1, 'foo.bar', 2);
      expect(fixture1['foo']['bar'], 2);

      setProperty(fixture1, 'foo.bar.baz', 3);
      expect(fixture1['foo']['bar']['baz'], 3);

      setProperty(fixture1, 'foo.bar', 'test');
      expect(fixture1['foo']['bar'], 'test');

      setProperty(fixture1, 'foo.bar', null);
      expect(fixture1['foo']['bar'], null);

      setProperty(fixture1, 'foo.bar', false);
      expect(fixture1['foo']['bar'], false);

      setProperty(fixture1, 'foo.bar', <dynamic>[]);
      expect(fixture1['foo']['bar'], <dynamic>[]);

      setProperty(fixture1, 'foo.bar', <String, dynamic>{});
      expect(fixture1['foo']['bar'], <String, dynamic>{});

      setProperty(fixture1, 'foo.fake.fake2', 'fake');
      expect(fixture1['foo']['fake']['fake2'], 'fake');

      setProperty(fixture1, 'foo\\.bar.baz', true);
      expect(fixture1['foo.bar']['baz'], true);

      setProperty(fixture1, 'fo\\.ob\\.ar.baz', true);
      expect(fixture1['fo.ob.ar']['baz'], true);

      final fixture2 = <String, dynamic>{'foo': null};
      setProperty(fixture2, 'foo.bar', 2);
      expect(fixture2['foo']['bar'], 2);

      const fixture4 = 'noobject';
      final output4 = setProperty(fixture4, 'foo.bar', 2);
      expect(fixture4, 'noobject');
      expect(fixture4, output4);

      final fixture5 = <dynamic>[];
      setProperty(fixture5, '[1]', true);
      expect(fixture5[1], true);

      setProperty(fixture5, '[0].foo[0]', true);
      expect(fixture5[0]['foo'][0], true);

      expect(() => setProperty(fixture5, '1', true),
          _matchArgumentErrorMessage('Cannot use string index'));

      expect(() => setProperty(fixture5, '0.foo.0', true),
          _matchArgumentErrorMessage('Cannot use string index'));

      final fixture6 = <String, dynamic>{};
      setProperty(fixture6, 'foo[0].bar', true);
      expect(fixture6['foo'][0]['bar'], true);
      expect(
          fixture6,
          equals({
            'foo': <dynamic>[
              <String, dynamic>{'bar': true}
            ]
          }));

      // dart no supported
      // const fixture7 = {foo: ['bar', 'baz']};
      // setProperty(fixture7, 'foo.length', 1);
      // t.is(fixture7.foo.length, 1);
      // t.deepEqual(fixture7, {foo: ['bar']});
    });

    test('array get/set test', () {
      Map<String, dynamic> fixture1 = {
        'foo': <dynamic>[],
      };
      final foo = fixture1['foo'] as List<dynamic>;
      setProperty(fixture1, 'foo[0]', 'bar');
      expect(foo.length, 1);
      expect(foo.first, 'bar');
      expect(getProperty(fixture1, 'foo[0]'), 'bar');

      setProperty(fixture1, 'foo[0]', 'baz');
      expect(foo.length, 1);
      expect(foo.first, 'baz');
      expect(getProperty(fixture1, 'foo[0]'), 'baz');

      setProperty(fixture1, 'foo[1]', 1);
      expect(foo.length, 2);
      expect(foo.first, 'baz');
      expect(foo.last, 1);
      expect(getProperty(fixture1, 'foo[0]'), 'baz');
      expect(getProperty(fixture1, 'foo[1]'), 1);
    });

    test('deleteProperty', () {
      final inner = <String, dynamic>{
        'a': 'a',
        'b': 'b',
        'c': 'c',
      };
      final fixture1 = <String, dynamic>{
        'foo': {
          'bar': {
            'baz': inner,
          },
        },
        'top': {
          'dog': 'sindre',
        },
      };

      expect(fixture1['foo']['bar']['baz']['c'], 'c');
      expect(deleteProperty(fixture1, 'foo.bar.baz.c'), true);
      expect(fixture1['foo']['bar']['baz']['c'], null);

      expect(fixture1['top']['dog'], 'sindre');
      expect(deleteProperty(fixture1, 'top.dog'), true);
      expect(fixture1['top']['dog'], null);

      setProperty(fixture1, 'foo\\.bar.baz', true);
      expect(fixture1['foo.bar']['baz'], true);
      expect(deleteProperty(fixture1, 'foo\\.bar.baz'), true);
      expect(fixture1['foo.bar']['baz'], null);

      final fixture2 = <String, dynamic>{};
      setProperty(fixture2, 'foo.bar\\.baz', true);
      expect(fixture2['foo']['bar.baz'], true);
      expect(deleteProperty(fixture2, 'foo.bar\\.baz'), true);
      expect(fixture2['foo']['bar.baz'], null);

      fixture2['dotted'] = <String, dynamic>{
        'sub': {
          'dotted.prop': 'foo',
          'other': 'prop',
        },
      };
      expect(deleteProperty(fixture2, 'dotted.sub.dotted\\.prop'), true);
      expect(fixture2['dotted']['sub']['dotted.prop'], null);
      expect(fixture2['dotted']['sub']['other'], 'prop');

      final fixture3 = {'foo': null};
      expect(deleteProperty(fixture3, 'foo.bar'), false);
      expect(fixture3, equals({'foo': null}));

      final fixture4 = <dynamic>[
        <String, dynamic>{
          'top': <String, dynamic>{
            'dog': 'sindre',
          },
        }
      ];

      expect(() => deleteProperty(fixture4, '0.top.dog'),
          _matchArgumentErrorMessage('Cannot use string index'));
      expect(deleteProperty(fixture4, '[0].top.dog'), true);
      expect(
          fixture4,
          equals([
            {'top': <String, dynamic>{}}
          ]));

      final fixture5 = <String, dynamic>{
        'foo': <dynamic>[
          <String, dynamic>{
            'bar': <dynamic>['foo', 'bar'],
          }
        ],
      };

      deleteProperty(fixture5, 'foo[0].bar[0]');

      final fixtureArray = <dynamic>[null, 'bar'];

      expect(
          fixture5,
          equals({
            'foo': [
              {'bar': fixtureArray}
            ]
          }));
    });

    test('hasProperty', () {
      final fixture1 = <String, dynamic>{
        'foo': <String, dynamic>{'bar': 1}
      };
      expect(hasProperty(fixture1, ''), false);
      expect(hasProperty(fixture1, 'foo'), true);
      expect(hasProperty({'foo': 1}, 'foo'), true);
      expect(hasProperty({'foo': null}, 'foo'), true);
      expect(
          hasProperty({
            'foo': {'bar': true}
          }, 'foo.bar'),
          true);
      expect(
          hasProperty({
            'foo': {
              'bar': {'baz': true}
            }
          }, 'foo.bar.baz'),
          true);
      expect(
          hasProperty({
            'foo': {
              'bar': {'baz': null}
            }
          }, 'foo.bar.baz'),
          true);
      expect(
          hasProperty({
            'foo': {'bar': 'a'}
          }, 'foo.fake.fake2'),
          false);
      expect(hasProperty({'foo': null}, 'foo.bar'), false);
      expect(hasProperty({'foo': ''}, 'foo.bar'), false);

      expect(
          hasProperty({
            'foo.baz': {'bar': true}
          }, 'foo\\.baz.bar'),
          true);
      expect(
          hasProperty({
            'fo.ob.az': {'bar': true}
          }, 'fo\\.ob\\.az.bar'),
          true);
      expect(hasProperty(null, 'fo\\.ob\\.az.bar'), false);

      expect(
          hasProperty({
            'foo': [
              {
                'bar': ['bar', 'bizz']
              }
            ],
          }, 'foo[0].bar.1'),
          false);
      expect(
          hasProperty({
            'foo': [
              {
                'bar': ['bar', 'bizz']
              }
            ],
          }, 'foo[0].bar.2'),
          false);
      expect(
          hasProperty({
            'foo': [
              {
                'bar': ['bar', 'bizz']
              }
            ],
          }, 'foo[1].bar.1'),
          false);
      expect(
          hasProperty({
            'foo': [
              {
                'bar': {
                  '1': 'bar',
                },
              }
            ],
          }, 'foo[0].bar.1'),
          true);
    });

    test('escapePath', () {
      // expect(escapePath('foo.bar[0]'), 'foo\\.bar\\[0]');
      expect(escapePath('foo\\.bar[0]'), 'foo\\\\\\.bar\\[0]');
      expect(escapePath('foo\\\\.bar[0]'), 'foo\\\\\\\\\\.bar\\[0]');
      expect(
          escapePath('foo\\\\.bar\\\\[0]'), 'foo\\\\\\\\\\.bar\\\\\\\\\\[0]');
      expect(escapePath('foo[0].bar'), 'foo\\[0]\\.bar');
      expect(escapePath('foo.bar[0].baz'), 'foo\\.bar\\[0]\\.baz');
      expect(escapePath('[0].foo'), '\\[0]\\.foo');
      expect(escapePath('\\foo'), '\\\\foo');
      expect(escapePath('foo\\'), 'foo\\\\');
      expect(escapePath('foo\\\\'), 'foo\\\\\\\\');
      expect(escapePath(''), '');
    });

    test('deepKeys', () {
      const object = {
        'eo': <dynamic, dynamic>{},
        'ea': <dynamic>[],
        'a.b': {
          'c': {
            'd': [
              1,
              2,
              {
                'g': 3,
              }
            ],
            'e': '🦄',
            'f': 0,
            'h': <dynamic, dynamic>{},
            'i': <dynamic>[],
            'nu': null,
            'na': double.infinity,
          },
          '': {
            'a': 0,
          },
        },
        '': {
          'a': 0,
        },
      };

      final keys = deepKeys(object);
      expect(
          keys,
          equals([
            'eo',
            'ea',
            'a\\.b.c.d[0]',
            'a\\.b.c.d[1]',
            'a\\.b.c.d[2].g',
            'a\\.b.c.e',
            'a\\.b.c.f',
            'a\\.b.c.h',
            'a\\.b.c.i',
            'a\\.b.c.nu',
            'a\\.b.c.na',
            'a\\.b..a',
            '.a',
          ]));

      for (final key in keys) {
        expect(hasProperty(object, key), true);
      }

      expect(deepKeys(<dynamic>[]), equals(<String>[]));
      expect(deepKeys(0), equals(<String>[]));
    });
  });
}

Matcher _matchArgumentErrorMessage(String message) {
  return throwsA(
      predicate<dynamic>((e) => e is ArgumentError && e.message == message));
}
