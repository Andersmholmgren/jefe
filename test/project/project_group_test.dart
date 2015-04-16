library devops.project.group.test;

import 'package:devops/src/dependency_graph.dart';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:devops/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:devops/src/pubspec/pubspec.dart';
import 'dart:async';
import 'package:devops/src/pubspec/dependency.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:logging/logging.dart';
import 'package:devops/src/project_group_impl.dart';
import 'package:devops/src/spec/JefeSpec.dart';
import 'dart:io';
import 'test_helpers.dart';

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(print);
  hierarchicalLoggingEnabled = true;

  group('allProjects', () {
    final group1 = aGroup('group1', [], []);

    final project1 = aProject('project1');
    final project2 = aProject('project2');
    final project3 = aProject('project3');

    final group2 = aGroup('group2', [group1], [project1, project2]);

    final group3 = aGroup('group3', [group2], []);

    final group4 = aGroup('group4', [group2], [project3]);

    final group5 = aGroup(
        'group5', [group1, group2, group1], [project1, project3, project1]);

    test('when no projects or child groups then result is empty', () async {
      expect(await group1.allProjects, isEmpty);
    });

    test(
        'when group contains projects and empty child group then result is projects',
        () async {
      expect(await group2.allProjects, unorderedEquals([project2, project1]));
    });

    test(
        'when group no projects and child group that contains projects then result is projects',
        () async {
      expect(await group3.allProjects, unorderedEquals([project2, project1]));
    });

    test(
        'when group contains projects and child group with projects then result is all projects',
        () async {
      expect(await group4.allProjects,
          unorderedEquals([project2, project1, project3]));
    });
    test(
        'when group contains duplicate projects and duplicate child group with projects then result is all projects',
        () async {
      expect(await group5.allProjects,
          unorderedEquals([project2, project1, project3]));
    });
  });
}

ProjectGroupImpl aGroup(
    String name, Iterable<ProjectGroup> groups, Iterable<Project> projects) {
  final metaData = new ProjectGroupMetaDataImpl(
      name, groups.map((g) => g.id), projects.map((p) => p.id));

  final factory = new TestProjectEntityReferenceFactory(groups, projects);

  final directoryLayout = new GroupDirectoryLayout(new Directory('foo'), name);

  return new ProjectGroupImpl('git:$name', metaData, directoryLayout,
      referenceFactory: factory);
}

class TestProjectEntityReferenceFactory
    implements ProjectEntityReferenceFactory {
  final Map<ProjectGroupIdentifier, ProjectGroupReference> _groupMap;
  final Map<ProjectIdentifier, ProjectReference> _projectMap;

  TestProjectEntityReferenceFactory._(this._groupMap, this._projectMap);

  factory TestProjectEntityReferenceFactory(
      Iterable<ProjectGroup> groups, Iterable<Project> projects) {
    final Map<ProjectGroupIdentifier, ProjectGroupReference> gm = {};
    final Map<ProjectIdentifier, ProjectReference> pm = {};

    groups.forEach((g) {
      gm[g.id] = new TestProjectGroupReference(g);
    });

    projects.forEach((p) {
      pm[p.id] = new TestProjectReference(p);
    });

    return new TestProjectEntityReferenceFactory._(gm, pm);
  }

  ProjectGroupReference createGroupReference(
      ProjectGroupImpl group, ProjectGroupIdentifier id) => _groupMap[id];

  ProjectReference createProjectReference(
      ProjectGroupImpl group, ProjectIdentifier id) => _projectMap[id];
}

class TestProjectGroupReference implements ProjectGroupReference {
  final ProjectGroupImpl group;

  TestProjectGroupReference(this.group);

  @override
  Future<ProjectGroup> get() async => group;

  @override
  String get gitUri => group.gitUri;

  @override
  String get name => group.name;
}

class TestProjectReference implements ProjectReference {
  final Project project;

  TestProjectReference(this.project);

  @override
  Future<Project> get() async => project;

  @override
  String get gitUri => project.gitUri;

  @override
  String get name => project.name;
}
