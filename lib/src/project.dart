library devops.project;

import 'dart:async';
import 'dart:io';
import 'project_impl.dart';
import 'project_yaml.dart';
import 'package:path/path.dart' as p;
import 'package:git/git.dart';
import 'package:devops/src/pubspec/pubspec.dart';
import 'package:pub_semver/pub_semver.dart';

abstract class Ref<T> {
  String get name;
  String get gitUri;

  Future<T> install(Directory parentDirectory, {bool recursive: true});

  Future<T> load(Directory parentDirectory, {bool recursive: true});
}

abstract class ProjectGroupRef implements Ref<ProjectGroup> {
  factory ProjectGroupRef.fromGitUrl(
      String name, String gitUri) = ProjectGroupRefImpl;
}

abstract class ProjectRef implements Ref<Project> {
  factory ProjectRef.fromGitUrl(String name, String gitUri) = ProjectRefImpl;
}

abstract class ProjectEntity {
  String get gitUri;
  Future<GitDir> get gitDir;
  Directory get installDirectory;
}

abstract class ProjectGroup extends ProjectEntity {
  ProjectGroupMetaData get metaData;

  static Future<ProjectGroup> install(
      String name, String gitUri, Directory parentDir,
      {bool recursive: true}) => new ProjectGroupRef.fromGitUrl(name, gitUri)
      .install(parentDir, recursive: recursive);

  static Future<ProjectGroup> fromInstallDirectory(
          Directory installDirectory) =>
      loadProjectGroupFromInstallDirectory(installDirectory);

  Future<ProjectGroup> childProjectGroup(ProjectGroupRef ref);

  Future<Set<Project>> get allProjects;

  Future processDependenciesDepthFirst(
      process(Project project, Iterable<Project> dependencies));

  Future update({bool recursive: true});
  Future setupForNewFeature(String featureName, {bool recursive: true});
  Future release({bool recursive: true, ReleaseType type: ReleaseType.minor});

  Future setToPathDependencies({bool recursive: true});
  Future setToGitDependencies({bool recursive: true});

  Future commit(String message);
  Future push();

  Future initFlow({bool recursive: true});
  Future featureStart(String name, {bool recursive: true});
  Future featureFinish(String name, {bool recursive: true});
  Future releaseStart(String version, {bool recursive: true});
  Future releaseFinish(String version, {bool recursive: true});

  Future pubGet();

  // May also be possible to checkout a particular version and create a bugfix
  // branch off it
  //  e.g Future checkout(String version, {bool recursive: true});
}

abstract class Project extends ProjectEntity {
  PubSpec get pubspec;

  static Future<Project> install(
      String name, String gitUri, Directory parentDir,
      {bool recursive: true}) => new ProjectRef.fromGitUrl(name, gitUri)
      .install(parentDir, recursive: recursive);

  static Future<Project> fromInstallDirectory(Directory installDirectory) =>
      loadProjectFromInstallDirectory(installDirectory);

  Future release(Iterable<Project> dependencies,
      {ReleaseType type: ReleaseType.minor});

  Future updatePubspec(PubSpec newSpec);

  Future commit(String message);

  Future push();

  Future initFlow();
  Future featureStart(String featureName);
  Future featureFinish(String featureName);
  Future releaseStart(String version);
  Future releaseFinish(String version);

  Future setToPathDependencies(Iterable<Project> dependencies);

  Future setToGitDependencies(Iterable<Project> dependencies);

  Future pubGet();
}

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
