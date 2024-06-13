Get, set, or delete a property from a nested object using a dot path.

This is the Dart implementation of [dot-prop](https://www.npmjs.com/package/dot-prop).

## Getting started

```dart
import 'package:dot_prop/dot_prop.dart';

void main() {
  final data = {
    'user': {'name': 'foo'}
  };

  getProperty(data, 'user.name'); // => 'foo'
  hasProperty(data, 'user.name'); // => true

  setProperty(data, 'user.name', 'newname');
  getProperty(data, 'user.name'); // => 'newname'

  deleteProperty(data, 'user.name');
  hasProperty(data, 'user.name'); // => false
  getProperty(data, 'user.name'); // => null
}
```

## Usage

If location of path doesn't exist, it will created.

```dart
final root = <String, dynamic>{};
const key = 'foo.bar.abc';

setProperty(root, key, 1);
expect(root['foo']['bar']['abc'], equals(1));
expect(getProperty(root, key, defaultValue), equals(1));
```

### array

Arrays can be accessed using `[index]` notation.

```dart
final root = <dynamic>[];

setProperty(root, '[0].foo[0]', true);
expect(root[0]['foo'][0], true);
```