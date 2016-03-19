import 'package:test/test.dart';
import 'dart:io';
import 'test_project_utils.dart';

main() {
  group('', () {
    setUp(() async {
      final projects = await createTestProjects(4);
      print(projects);
//      final projectDir = await copyTestProject('project1');
//      print(projectDir);
//      print(project.name);
//      print(project.installDirectory);
    });

    test('', () {}, skip: false);
  }, skip: false);
}
