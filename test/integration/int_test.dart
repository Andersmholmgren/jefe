import 'package:test/test.dart';
import 'dart:io';
import 'test_project_utils.dart';
import 'package:jefe/jefe.dart';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';
import 'dart:async';
import 'package:git/git.dart';

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

    group('results in remote repos in expected state', () {
      ProjectGroupMetaData metaData;

      Directory projectDirectory(int projectCount) =>
          new Directory(metaData.projects
              .where((pi) => pi.name == 'project$projectCount')
              .map((pi) => pi.gitUri)
              .first);

//      Future<GitDir> projectGitDir(int projectCount) async =>
//      GitDir.fromExisting();
      Future<ProcessResult> runGitCommand(
          Iterable<String> args, Directory processWorkingDir,
          [bool throwOnError = true]) {
        final list = args.toList();

        return runGit(list,
            throwOnError: throwOnError,
            processWorkingDir: processWorkingDir.path);
      }

      Future<Map<String, Commit>> getCommits(Directory processWorkingDir,
          [String branchName = 'HEAD']) async {
        var pr = await runGitCommand(
            ['rev-list', '--format=raw', branchName], processWorkingDir);
        return Commit.parseRawRevList(pr.stdout);
      }

      Future<Map<String, Commit>> getCommitsFor(int projectCount,
              [String branchName = 'HEAD']) async =>
          getCommits(projectDirectory(projectCount), branchName);

      setUp(() async {
        if (metaData == null)
          metaData = await ProjectGroupMetaData
              .fromDefaultProjectGroupYamlFile(jefeDir.path);

//        metaData.projects.map((pi) => pi.gitUri)
      });

      group('with project2 commits', () {
        Map<String, Commit> commits;
        setUp(() async {
          commits = await getCommitsFor(2, 'master');
        });

        test('with expected number', () {
          expect(commits, hasLength(4));
        }, skip: false);

        test('with expected messages', () {
          expect(commits.values.map((c) => c.message), [
            "Merge branch 'release/0.0.1'",
            "completed development of feature addDependencies",
            "added dependency on project1",
            "blah"
          ]);
        }, skip: false);
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
