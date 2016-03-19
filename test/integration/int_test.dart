import 'package:test/test.dart';
import 'dart:io';
import 'test_project_utils.dart';

main() {
  group('', () {
    setUp(() async {
      final project = await copyTestProject('fred');
      print(project.name);
      print(project.installDirectory);
    });

    test('', () {}, skip: false);
  }, skip: false);
}
