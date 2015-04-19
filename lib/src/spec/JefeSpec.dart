library devops.project.spec;

import 'dart:async';
import 'dart:io';
import 'package:devops/devops.dart';
import 'package:devops/src/project/project_yaml.dart';
import 'package:path/path.dart' as p;

abstract class ProjectGroupMetaData {
//  factory ProjectGroupMetaData = ProjectGroupMetaDataImpl;

  String get name;

  Iterable<ProjectGroupIdentifier> get childGroups;

  Iterable<ProjectIdentifier> get projects;

  static Future<ProjectGroupMetaData> fromDefaultProjectGroupYamlFile(
          String projectGroupDirectory) =>
      fromProjectGroupYamlFile(p.join(projectGroupDirectory, 'project.yaml'));

  static Future<ProjectGroupMetaData> fromProjectGroupYamlFile(
          String projectGroupFile) =>
      readProjectGroupYaml(new File(projectGroupFile));
}

class ProjectGroupMetaDataImpl implements ProjectGroupMetaData {
  final String name;
  final Iterable<ProjectGroupIdentifier> childGroups;
  final Iterable<ProjectIdentifier> projects;

  ProjectGroupMetaDataImpl(this.name, this.childGroups, this.projects);
}

abstract class ProjectEntityIdentifier<T> {
  String get name;
  String get gitUri;

//  @deprecated // unless we can find a way to encapsulate folder layout
//  Future<T> install(Directory parentDirectory, {bool recursive: true});
//
//  @deprecated // unless we can find a way to encapsulate folder layout
//  Future<T> load(Directory parentDirectory, {bool recursive: true});

}

abstract class ProjectGroupIdentifier
    implements ProjectEntityIdentifier<ProjectGroup> {
  factory ProjectGroupIdentifier(
      String name, String gitUri) = ProjectGroupRefImpl;
}

abstract class ProjectIdentifier implements ProjectEntityIdentifier<Project> {
  factory ProjectIdentifier(String name, String gitUri) = ProjectIdentifierImpl;
}

//TODO: fix ^^

abstract class _BaseRef<T> implements ProjectEntityIdentifier<T> {
  final String name;
  final String gitUri;

  _BaseRef(this.name, this.gitUri);

  @deprecated
  Directory installDirectory(Directory parent) =>
      new Directory(p.join(parent.path, name));

  bool operator ==(other) => other.runtimeType == runtimeType &&
      name == other.name &&
      gitUri == other.gitUri;

  int get hashCode => name.hashCode;
}

class ProjectGroupRefImpl extends _BaseRef implements ProjectGroupIdentifier {
  ProjectGroupRefImpl(String name, String gitUri) : super(name, gitUri);

//  @override
//  Future<ProjectGroup> install(Directory parentDir, {bool recursive: true}) =>
//      ProjectGroup.install(parentDir, name, gitUri, recursive: recursive);
//
//  Directory installDirectory(Directory parent) =>
//      super.installDirectory(_containerDirectory(parent));
//
//  Directory _containerDirectory(Directory parentDir) =>
//      new Directory(gitWorkspacePath(gitUri, parentDir) + '_root');

//  @override
//  Future<ProjectGroup> load(Directory parentDirectory,
//          {bool recursive: true}) =>
//      ProjectGroup.fromInstallDirectory(parentDirectory);

  String toString() => 'ProjectGroupRef($name, $gitUri)';
}

class ProjectIdentifierImpl extends _BaseRef implements ProjectIdentifier {
  ProjectIdentifierImpl(String name, String gitUri) : super(name, gitUri);

//  @override
//  Future<Project> install(Directory parentDir, {bool recursive: true}) async {
//    _log.info('installing project $name from $gitUri into $parentDir');
//
//    final GitDir gitDir = await clone(gitUri, parentDir);
//    final installDirectory = new Directory(gitDir.path);
//    return new ProjectImpl(
//        gitUri, installDirectory, await PubSpec.load(installDirectory));
//  }
//
//  @override
//  Future<Project> load(Directory parentDirectory, {bool recursive: true}) =>
//      Project.fromInstallDirectory(installDirectory(parentDirectory));
  String toString() => 'ProjectRef($name, $gitUri)';
}
