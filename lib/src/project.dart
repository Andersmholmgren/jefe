library devops.project;

import 'dart:async';
import 'dart:io';
import 'project_impl.dart';
import 'package:git/git.dart';
import 'package:devops/src/pubspec/pubspec.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:devops/src/project_group_impl.dart';
import 'package:devops/src/spec/JefeSpec.dart';

abstract class ProjectEntityReference<T extends ProjectEntity>
    extends ProjectEntityIdentifier {
//  String get name;
//  String get gitUri;

//  Future<T> install();

  Future<T> get();
}

abstract class ProjectGroupReference
    implements ProjectEntityReference<ProjectGroup> {
//  factory ProjectGroupRef.fromGitUrl(
//      String name, String gitUri) = ProjectGroupRefImpl;
}

abstract class ProjectReference implements ProjectEntityReference<Project> {
//  factory ProjectRef.fromGitUrl(String name, String gitUri) = ProjectRefImpl;
}

abstract class ProjectEntity {
  String get name;
  String get gitUri;
  Future<GitDir> get gitDir;
  Directory get installDirectory;
}

abstract class ProjectSource {
  Future visitAllProjects(process(Project project));

  Future processDependenciesDepthFirst(
      process(Project project, Iterable<Project> dependencies));

  Future<Iterable<Project>> get projects;

  Directory get containerDirectory;
}

abstract class ProjectGroup extends ProjectEntity implements ProjectSource {
//  ProjectGroupMetaData get metaData;
  ProjectGroupIdentifier get id;

  // TODO: make name optional. Derive from gitUri
  static Future<ProjectGroup> install(Directory parentDir, String gitUri,
      {String name}) => ProjectGroupImpl.install(parentDir, gitUri, name: name);

  static Future<ProjectGroup> load(Directory installDirectory) =>
      ProjectGroupImpl.load(installDirectory);

//  Future<ProjectGroup> childProjectGroup(ProjectGroupRef ref);

  // the directory that is the container for the group.
  // Typically named <groupName>_root
  Directory get containerDirectory;

  Future<Set<Project>> get allProjects;

  Future processDependenciesDepthFirst(
      process(Project project, Iterable<Project> dependencies));
}

abstract class Project extends ProjectEntity {
  PubSpec get pubspec;
  ProjectIdentifier get id;

  static Future<Project> install(
          Directory parentDir, String name, String gitUri,
          {bool recursive: true}) =>
      ProjectImpl.install(parentDir, name, gitUri, recursive: recursive);

  static Future<Project> load(Directory installDirectory) =>
      ProjectImpl.load(installDirectory);

  Future<String> get currentGitCommitHash;

  Future updatePubspec(PubSpec newSpec);
}

//enum ReleaseType { major, minor, patch }

typedef Version _VersionBumper(Version current);

Version _bumpMinor(Version v) => v.nextMinor;
Version _bumpMajor(Version v) => v.nextMajor;
Version _bumpPatch(Version v) => v.nextPatch;
Version _bumpBreaking(Version v) => v.nextBreaking;

class ReleaseType {
  final _VersionBumper _bump;
  const ReleaseType._(this._bump);

  static const ReleaseType minor = const ReleaseType._(_bumpMinor);

  static const ReleaseType major = const ReleaseType._(_bumpMajor);

  static const ReleaseType patch = const ReleaseType._(_bumpPatch);

  static const ReleaseType breaking = const ReleaseType._(_bumpBreaking);

  Version bump(Version version) => _bump(version);
}
