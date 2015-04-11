library devops.project;

import 'dart:async';
import 'dart:io';
import 'project_impl.dart';
import 'project_yaml.dart';
import 'package:path/path.dart' as p;
import 'package:den_api/den_api.dart';
import 'package:git/git.dart';

abstract class Ref<T> {
  String get name;
  Uri get gitUri;

  Future<T> install(Directory parentDirectory, {bool recursive: true});

  Future<T> load(Directory parentDirectory, {bool recursive: true});
}

abstract class ProjectGroupRef implements Ref<ProjectGroup> {
  factory ProjectGroupRef.fromGitUrl(
      String name, Uri gitUri) = ProjectGroupRefImpl;
}

abstract class ProjectRef implements Ref<Project> {
  factory ProjectRef.fromGitUrl(String name, Uri gitUri) = ProjectRefImpl;
}

abstract class ProjectEntity {
  Uri get gitUri;
  Future<GitDir> get gitDir;
  Directory get installDirectory;
}

abstract class ProjectGroup extends ProjectEntity {
  ProjectGroupMetaData get metaData;

  static Future<ProjectGroup> install(
      String name, Uri gitUri, Directory parentDir,
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
  Future setupForDev({bool recursive: true});
  Future release({bool recursive: true, ReleaseType type: ReleaseType.minor});

  Future initFlow({bool recursive: true});
  Future featureStart(String name, {bool recursive: true});
  Future featureEnd(String name, {bool recursive: true});

  // May also be possible to checkout a particular version and create a bugfix
  // branch off it
  //  e.g Future checkout(String version, {bool recursive: true});
}

abstract class Project extends ProjectEntity {
  Future<Pubspec> get pubspec;

  static Future<Project> install(String name, Uri gitUri, Directory parentDir,
      {bool recursive: true}) => new ProjectRef.fromGitUrl(name, gitUri)
      .install(parentDir, recursive: recursive);

  static Future<Project> fromInstallDirectory(Directory installDirectory) =>
      loadProjectFromInstallDirectory(installDirectory);

  Future initFlow();

  Future featureStart(String featureName);

  Future setDevDependencies(Iterable<Project> dependencies);
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
