import 'package:test/test.dart';
import 'dart:io';
import 'test_project_utils.dart';
import 'package:jefe/jefe.dart';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';
import 'dart:async';

final Logger _log = new Logger('dd');

main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(print);

  group('simple lifecycle with a dependency added', () {
    Directory jefeDir;
    setUp(() async {
      // too expensive to set up each test
      if (jefeDir == null) jefeDir = await _performLifecycle;
    });

//    test('', () {}, skip: false);
    group('has expected jefe yaml', () {
      ProjectGroupMetaData metaData;

      setUp(() async {
        if (metaData == null)
          metaData = await ProjectGroupMetaData
              .fromDefaultProjectGroupYamlFile(jefeDir.path);
      });

      test('with four projects', () {
        expect(metaData.projects, hasLength(4));
      }, skip: false);

      test('with expected project names', () {
        expect(metaData.projects.map((pi) => pi.name),
            unorderedEquals(['project1', 'project2', 'project3', 'project4']));
      }, skip: false);

      test('with expected project gitUri', () {
        expect(
            metaData.projects.map((pi) => pi.gitUri),
            unorderedEquals(['project1', 'project2', 'project3', 'project4']
                .map((s) => p.join(jefeDir.parent.path, s))));
      }, skip: false);
    }, skip: false);
  }, skip: false);
}

Future get _performLifecycle async {
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

  // TODO: damn. Need to reload the group here as they are now stale.
  final group3 = await ProjectGroup.load(group.containerDirectory);

  await (await group3.rootJefeProjects).lifecycle.release();

  return jefeDir;
}
