import 'package:test/test.dart';
import 'dart:io';
import 'test_project_utils.dart';
import 'package:jefe/jefe.dart';
import 'package:path/path.dart' as p;

main() {
  group('', () {
    setUp(() async {
      final project1 = aProject('project1');
      final project2 = aProject('project2', dependencies: [project1]);
      final project3 = aProject('project3');
      final project4 = aProject('project4', dependencies: [project3, project2]);

      final jefeDir = await createJefeWithTestProjects(4);
      print(jefeDir);

      final parentDirectory =
          await new Directory(p.join(jefeDir.parent.parent.path, 'installDirs'))
              .create();

      final group = await ProjectGroup.install(parentDirectory, jefeDir.path);
      print(group);
//      final projectDir = await copyTestProject('project1');
//      print(projectDir);
//      print(project.name);
//      print(project.installDirectory);
    });

    test('', () {}, skip: false);
  }, skip: false);
}
