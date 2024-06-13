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
