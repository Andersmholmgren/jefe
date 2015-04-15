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

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(print);
  hierarchicalLoggingEnabled = true;

  group('allProjects', () {
    new ProjectGroupImpl();
//    String gitUri, this.metaData, GroupDirectoryLayout directoryLayout,
//  {ProjectEntityReferenceFactory referenceFactory: const DefaultProjectEntityReferenceFactory()})
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
      gm[new ProjectGroupIdentifier(g.name, g.gitUri)] =
          new TestProjectGroupReference(g);
    });

    projects.forEach((p) {
      pm[new ProjectIdentifier(p.name, p.gitUri)] = new TestProjectReference(p);
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
