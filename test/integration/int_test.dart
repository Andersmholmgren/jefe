import 'package:test/test.dart';
import 'dart:io';
import 'test_project_utils.dart';
import 'package:jefe/jefe.dart';
import 'package:path/path.dart' as p;

main() {
  group('', () {
    setUp(() async {
      final projects = await createTestProjects(4);
      print(projects);
//      final projectDir = await copyTestProject('project1');
//      print(projectDir);
//      print(project.name);
//      print(project.installDirectory);

      final jefeFile = new ProjectGroupMetaData('testGroup', [], projects.map((d) {
        final projectName = p.basename(d.path);
        return new ProjectIdentifier(projectName, d.path);
      }));

      await jefeFile.save(projects.first.parent);

    });

    test('', () {}, skip: false);
  }, skip: false);
}
