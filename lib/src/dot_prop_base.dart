import 'package:characters/characters.dart';

const _digits = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};
const _disallowedKeys = <String>{};

bool _isObject(dynamic value) {
  return value is List || value is Map<String, dynamic>;
}

List<dynamic> _getPathSegments(String path) {
  final parts = <dynamic>[];
  String currentSegment = '';
  String currentPart = 'start';
  bool isIgnoring = false;
  for (final character in path.iterable(unicode: true)) {
    switch (character) {
      case '\\':
        if (currentPart == 'index') {
          throw ArgumentError('Invalid character in an index');
        }

        if (currentPart == 'indexEnd') {
          throw ArgumentError('Invalid character after an index');
        }

        if (isIgnoring) {
          currentSegment += character;
        }
        currentPart = 'property';
        isIgnoring = !isIgnoring;

      case '.':
        if (currentPart == 'index') {
          throw ArgumentError('Invalid character in an index');
        }

        if (currentPart == 'indexEnd') {
          currentPart = 'property';
          break;
        }

        if (isIgnoring) {
          isIgnoring = false;
          currentSegment += character;
          break;
        }

        if (_disallowedKeys.contains(currentSegment)) {
          return [];
        }

        parts.add(currentSegment);
        currentSegment = '';
        currentPart = 'property';

      case '[':
        if (currentPart == 'index') {
          throw ArgumentError('Invalid character in an index');
        }

        if (currentPart == 'indexEnd') {
          currentPart = 'index';
          break;
        }

        if (isIgnoring) {
          isIgnoring = false;
          currentSegment += character;
          break;
        }

        if (currentPart == 'property') {
          if (_disallowedKeys.contains(currentSegment)) {
            return [];
          }

          parts.add(currentSegment);
          currentSegment = '';
        }

        currentPart = 'index';

      case ']':
        if (currentPart == 'index') {
          parts.add(int.parse(currentSegment));
          currentSegment = '';
          currentPart = 'indexEnd';
          break;
        }

        if (currentPart == 'indexEnd') {
          throw ArgumentError('Invalid character after an index');
        }
        continue defaultCase;

      defaultCase:
      default:
        if (currentPart == 'index' && !_digits.contains(character)) {
          throw ArgumentError('Invalid character in an index');
        }

        if (currentPart == 'indexEnd') {
          throw ArgumentError('Invalid character after an index');
        }

        if (currentPart == 'start') {
          currentPart = 'property';
        }

        if (isIgnoring) {
          isIgnoring = false;
          currentSegment += '\\';
        }

        currentSegment += character;
    }
  }
  if (isIgnoring) {
    currentSegment += '\\';
  }

  switch (currentPart) {
    case 'property':
      if (_disallowedKeys.contains(currentSegment)) {
        return [];
      }

      parts.add(currentSegment);

    case 'index':
      throw ArgumentError('Index was not closed');

    case 'start':
      parts.add('');

    // No default
  }

  return parts;
}

/// Get the value of the property at the given path.
/// 
/// If not found, return [fallbackValue] if provided, otherwise return `null`.
dynamic getProperty(dynamic object, String path, [dynamic fallbackValue]) {
  if (!_isObject(object)) {
    return fallbackValue ?? object;
  }

  final pathArray = _getPathSegments(path);
  if (pathArray.isEmpty) {
    return fallbackValue;
  }

  dynamic localObject = object;

  for (int index = 0; index < pathArray.length; index++) {
    final key = pathArray[index];

    if (_isStringIndex(localObject, key)) {
      localObject = null;
    } else {
      if (localObject is Map<String, dynamic>) {
        localObject = localObject[key];
      } else if (localObject is List<dynamic> && key is int) {
        if (key < localObject.length) {
          localObject = localObject[key];
        } else {
          return fallbackValue;
        }
      } else {
        return fallbackValue;
      }
    }

    if (localObject == null) {
      if (index != pathArray.length - 1) {
        return fallbackValue;
      }

      break;
    }
  }

  return localObject ?? fallbackValue;
}

/// Set the property at the given path to the given value.
/// 
/// If location of path doesn't exist, it will created.
/// 
/// Returns the object.
dynamic setProperty(dynamic object, String path, dynamic value) {
  if (!_isObject(object)) {
    return object;
  }

  final root = object;
  dynamic currentObject = object;
  final pathArray = _getPathSegments(path);

  for (int index = 0; index < pathArray.length; index++) {
    final key = pathArray[index];

    _assertNotStringIndex(currentObject, key);

    if (index == pathArray.length - 1) {
      if (currentObject is List && key is int) {
        _fillListByNull(currentObject, key);
        currentObject.add(value);
      } else {
        currentObject[key] = value;
      }
    } else {
      bool currentObjectKeyIsObject = false;
      try {
        currentObjectKeyIsObject = _isObject(currentObject[key]);
      } on RangeError {
        currentObjectKeyIsObject = false;
      }

      if (!currentObjectKeyIsObject) {
        if (currentObject is List && key is int) {
          _fillListByNull(currentObject, key);
        }
        final newObject =
            pathArray[index + 1] is int ? <dynamic>[] : <String, dynamic>{};
        if (currentObject is List && key == currentObject.length) {
          currentObject.add(newObject);
        } else {
          currentObject[key] = newObject;
        }
      }
    }

    currentObject = currentObject[key];
  }

  return root;
}

/// Delete the property at the given path.
/// 
/// Returns a boolean of whether the property existed before being deleted.
bool deleteProperty(dynamic object, String path) {
  if (!_isObject(object)) {
    return false;
  }

  dynamic localObject = object;

  final pathArray = _getPathSegments(path);
  for (int index = 0; index < pathArray.length; index++) {
    final key = pathArray[index];

    _assertNotStringIndex(localObject, key);

    if (index == pathArray.length - 1) {
      if (localObject is Map<String, dynamic>) {
        localObject.remove(key);
        return true;
      } else if (localObject is List<dynamic> && key is int) {
        if (key < localObject.length) {
          localObject[key] = null;
          return true;
        }
      }
    }

    localObject = localObject[key];

    if (!_isObject(localObject)) {
      return false;
    }
  }
  return false;
}

/// Check whether the property at the given path exists.
bool hasProperty(dynamic object, String path) {
  if (!_isObject(object)) {
    return false;
  }
  final pathArray = _getPathSegments(path);
  dynamic localObject = object;
  if (pathArray.isEmpty) {
    return false;
  }
  for (final key in pathArray) {
    if (!_isObject(localObject) || _isStringIndex(object, key)) {
      return false;
    }
    if (localObject is Map<String, dynamic>) {
      if (!localObject.containsKey(key)) {
        return false;
      }
    }
    if (localObject is List<dynamic>) {
      if (key is int) {
        if (key >= localObject.length) {
          return false;
        }
      }
      if (key is String) {
        return false;
      }
    }

    localObject = localObject[key];
  }
  return true;
}

/// Escape special characters in a path. Useful for sanitizing user input.
String escapePath(String path) {
  final pattern = RegExp(r'[\\.[]');
  return path.replaceAllMapped(pattern, (match) {
    return '\\${match[0]}';
  });
}

bool _isStringIndex(dynamic obj, dynamic key) {
  if (obj is List && key is String) {
    final maybeIndex = int.tryParse(key);
    return maybeIndex != null;
  }
  return false;
}

void _assertNotStringIndex(dynamic obj, dynamic key) {
  if (_isStringIndex(obj, key)) {
    throw ArgumentError('Cannot use string index');
  }
}

/// Fills the List with `null` values until its length is at least `len`.
///
/// If the List's current length is already greater than or equal to `len`,
/// no changes will be made.
///
/// Example:
/// ```dart
/// final myList = [1, 2, 3];
/// _fillListByNull(myList, 5);
/// // myList is now [1, 2, 3, null, null]
/// ```
void _fillListByNull(List<dynamic> arr, int len) {
  while (arr.length < len) {
    arr.add(null);
  }
}

List<List<dynamic>> _entries(dynamic value) {
  final ret = <List<dynamic>>[];
  if (value is List) {
    for (int i = 0; i < value.length; ++i) {
      ret.add([i, value[i]]);
    }
    return ret;
  }
  if (value is Map<String, dynamic>) {
    for (final entry in value.entries) {
      ret.add([entry.key, entry.value]);
    }
    return ret;
  }
  return ret;
}

String _stringifyPath(List<dynamic> pathSegments) {
  String result = '';
  for (final [index, segment] in _entries(pathSegments)) {
    if (segment is int) {
      result += '[$segment]';
    } else {
      final slice = escapePath(segment as String);
      result += index == 0 ? slice : '.$slice';
    }
  }
  return result;
}

bool _isEmptyObject(dynamic value) {
  if (!_isObject(value)) {
    return false;
  }
  if (value is List) {
    return value.isEmpty;
  }
  if (value is Map<String, dynamic>) {
    return value.isEmpty;
  }
  return false;
}

Iterable<String> _deepKeysIterator(dynamic object,
    [List<dynamic> currentPath = const []]) sync* {
  if (!_isObject(object) || _isEmptyObject(object)) {
    if (currentPath.isNotEmpty) {
      yield _stringifyPath(currentPath);
    }
    return;
  }

  for (final [key, value] in _entries(object)) {
    yield* _deepKeysIterator(value, [...currentPath, key]);
  }
}

/// Returns an array of every path.
/// 
/// Non-empty plain objects and arrays are deeply recursed and are not themselves included.
List<String> deepKeys(dynamic object) {
  return [..._deepKeysIterator(object)];
}

extension on String {
  /// To iterate a [String]: `"Hello".iterable()`
  /// This will use simple characters. If you want to use Unicode Grapheme
  /// from the [Characters] library, passa [chars] true.
  Iterable<String> iterable({bool unicode = false}) sync* {
    if (unicode) {
      var iterator = Characters(this).iterator;
      while (iterator.moveNext()) {
        yield iterator.current;
      }
    } else {
      for (var i = 0; i < length; i++) {
        yield this[i];
      }
    }
  }
}
