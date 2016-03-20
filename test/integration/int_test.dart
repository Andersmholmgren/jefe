import 'package:test/test.dart';
import 'dart:io';
import 'test_project_utils.dart';
import 'package:jefe/jefe.dart';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';

final Logger _log = new Logger('dd');

main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(print);

  group('simple lifecycle with a dependency added', () {
    setUp(() async {

      final jefeDir = await createJefeWithTestProjects(4);
      print(jefeDir);

      final parentDirectory =
          await new Directory(p.join(jefeDir.parent.parent.path, 'installDirs'))
              .create();

      final group = await ProjectGroup.install(parentDirectory, jefeDir.path);
      print(group);

      final graph = await group.rootJefeProjects;

      await graph.lifecycle.init();

      await graph.lifecycle.startNewFeature('addDependencies');

      final project1 = graph.getProjectByName('project1').get();

      final project2 = graph.getProjectByName('project2').get();

      await project2.pubspecCommands.addDependencyOn(project1);

      await project2.git.commit('added dependency on project1');

      // TODO: damn. Need to reload the group here as they are now stale.
      final group2 = await ProjectGroup.load(group.containerDirectory);

      await (await group2.rootJefeProjects).lifecycle.completeFeature(doPush: true);
    });

    test('', () {}, skip: false);
  }, skip: false);
}
