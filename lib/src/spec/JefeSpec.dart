library devops.project.spec;

import 'dart:async';
import 'dart:io';
import 'package:devops/devops.dart';
import 'package:devops/src/project_yaml.dart';
import 'package:path/path.dart' as p;

abstract class ProjectGroupMetaData {
  String get name;

  Iterable<ProjectGroupRef> get childGroups;

  Iterable<ProjectRef> get projects;

  static Future<ProjectGroupMetaData> fromDefaultProjectGroupYamlFile(
          String projectGroupDirectory) =>
      fromProjectGroupYamlFile(p.join(projectGroupDirectory, 'project.yaml'));

  static Future<ProjectGroupMetaData> fromProjectGroupYamlFile(
          String projectGroupFile) =>
      readProjectGroupYaml(new File(projectGroupFile));
}

class ProjectGroupMetaDataImpl implements ProjectGroupMetaData {
  final String name;
  final Iterable<ProjectGroupRef> childGroups;
  final Iterable<ProjectRef> projects;

  ProjectGroupMetaDataImpl(this.name, this.childGroups, this.projects);
}

abstract class Ref<T> {
  String get name;
  String get gitUri;

//  @deprecated // unless we can find a way to encapsulate folder layout
//  Future<T> install(Directory parentDirectory, {bool recursive: true});
//
//  @deprecated // unless we can find a way to encapsulate folder layout
//  Future<T> load(Directory parentDirectory, {bool recursive: true});

  String toString() => 'Ref($name, $gitUri)';
}

abstract class ProjectGroupRef implements Ref<ProjectGroup> {
  factory ProjectGroupRef.fromGitUrl(
      String name, String gitUri) = ProjectGroupRefImpl;
}

abstract class ProjectRef implements Ref<Project> {
  factory ProjectRef.fromGitUrl(String name, String gitUri) = ProjectRefImpl;
}

//TODO: fix ^^

abstract class _BaseRef<T> implements Ref<T> {
  final String name;
  final String gitUri;

  _BaseRef(this.name, this.gitUri);

  @deprecated
  Directory installDirectory(Directory parent) =>
      new Directory(p.join(parent.path, name));
}

class ProjectGroupRefImpl extends _BaseRef implements ProjectGroupRef {
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
}

class ProjectRefImpl extends _BaseRef implements ProjectRef {
  ProjectRefImpl(String name, String gitUri) : super(name, gitUri);

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
}
