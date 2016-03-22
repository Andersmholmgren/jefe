import 'dart:async';
import 'dart:io';

import 'package:git/git.dart';
import 'package:jefe/jefe.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec/pubspec.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'test_project_utils.dart';

final Logger _log = new Logger('dd');

main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(print);

  group('simple lifecycle with a dependency added', () {
    Directory jefeDir;
    setUp(() async {
      // too expensive to set up each test
      if (jefeDir == null) jefeDir = await _performLifecycle();
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
          if (commits == null) commits = await getCommitsFor(2, 'master');
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

      group('with project2 pubspec.yaml', () {
        PubSpec pubSpec;
        setUp(() async {
          if (pubSpec == null) {
            final directory = projectDirectory(2);
            final pubSpecStr = (await runGitCommand(
                    ['show', 'master:pubspec.yaml'], directory))
                .stdout;

            pubSpec = new PubSpec.fromJson(loadYaml(pubSpecStr));
          }
        });

        test('has expected version', () {
          expect(pubSpec.version, new Version(0, 0, 1));
        }, skip: false);

        test('has git reference to project1', () {
          expect(pubSpec.dependencies['project1'],
              new isInstanceOf<GitReference>());
        }, skip: false);

        // TODO: test more details on git ref
      }, skip: false);

      test('with project1 having only the original commit', () async {
        expect(await getCommitsFor(1, 'master'), hasLength(1));
      }, skip: false);

      test('with project3 having only the original commit', () async {
        expect(await getCommitsFor(3, 'master'), hasLength(1));
      }, skip: false);

      test('with project4 having only the original commit', () async {
        expect(await getCommitsFor(4, 'master'), hasLength(1));
      }, skip: false);
    }, skip: false);
  }, skip: false);

  group('process commands', () {
    ProjectGroup group;
    JefeProjectGraph graph;
    final Map<String, String> _expectedResults = {
      'project1': 'bin\npubspec.yaml\n',
      'project2': 'bin\npubspec.yaml\n',
      'project3': 'bin\npubspec.yaml\n',
      'project4': 'bin\npubspec.yaml\n'
    };

    Map<String, String> process(Iterable<ProcessCommandResult> results) =>
        new Map.fromIterable(results,
            key: (r) => r.project.name, value: (r) => r.result.stdout);

    setUp(() async {
      if (group == null) {
        group = await _createTestGroup();
        graph = await group.rootJefeProjects;
      }
    });

    test('ls executes concurrently', () async {
      expect(process(await graph.processCommands.execute('ls', [])),
          _expectedResults);
    }, skip: false);

    test('ls executes serially', () async {
      expect(
          process(await graph
              .multiProjectCommands(
                  defaultConcurrencyMode:
                      CommandConcurrencyMode.serialDepthFirst)
              .processCommands
              .execute('ls', [])),
          _expectedResults);
    }, skip: false);
  }, skip: false);
}

Future<Directory> _performLifecycle() async {
  print("============== _performLifecycle");
  final jefeDir = await createJefeWithTestProjects(4);

  print('--------- $jefeDir');

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

  final pubspec = project2.pubspec;
  final newPubspec = pubspec.copy(version: pubspec.version.nextMinor);

  await newPubspec.save(project2.installDirectory);

  await project2.git.tag(newPubspec.version.toString());

  await project2.git.commit('added dependency on project1');

  // TODO: damn. Need to reload the group here as they are now stale.
  final group2 = await ProjectGroup.load(group.containerDirectory);

  await (await group2.rootJefeProjects).lifecycle.completeFeature();

  // TODO: damn. Need to reload the group here as they are now stale.
  final group3 = await ProjectGroup.load(group.containerDirectory);

  await (await group3.rootJefeProjects).lifecycle.release();

  return jefeDir;
}

//Future<Directory> _runExecCommands() async {
//  print("============== _runExecCommands");
//  final jefeDir = await createJefeWithTestProjects(4);
//
//  print('--------- $jefeDir');
//
//  final parentDirectory =
//  await new Directory(p.join(jefeDir.parent.parent.path, 'installDirs'))
//    .create();
//
//  final group = await ProjectGroup.install(parentDirectory, jefeDir.path);
//  print(group);
//
//  final graph = await group.rootJefeProjects;
//
////  await graph.lifecycle.init();
//
////  await graph.processCommands.execute('ls', []);
//
//  return jefeDir;
//}

Future<ProjectGroup> _createTestGroup() async {
  print("============== _runExecCommands");
  final jefeDir = await createJefeWithTestProjects(4);

  print('--------- $jefeDir');

  final parentDirectory =
      await new Directory(p.join(jefeDir.parent.parent.path, 'installDirs'))
          .create();

  final group = await ProjectGroup.install(parentDirectory, jefeDir.path);
  print(group);

  return group;
}
