library devops.project;

import 'dart:async';
import 'dart:io';
import 'project_impl.dart';
import 'project_yaml.dart';
import 'package:path/path.dart' as p;
import 'package:den_api/den_api.dart';

abstract class Ref<T> {
  String get name;
  Uri get gitUri;

  Future<T> install(Directory parentDir, {bool recursive: true});
}

abstract class ProjectGroupRef implements Ref<ProjectGroup> {
  factory ProjectGroupRef.fromGitUrl(
      String name, Uri gitUri) = ProjectGroupRefImpl;
}

abstract class ProjectRef implements Ref<Project> {
//  factory ProjectRef.fromGitUrl(Uri gitUri);
}

abstract class ProjectGroup {
  Uri get gitUri;
  ProjectGroupMetaData get metaData;
  Directory get installDirectory;

  static Future<ProjectGroup> fromInstallDirectory(
          Directory installDirectory) =>
      loadProjectGroupFromInstallDirectory(installDirectory);

//  factory ProjectGroup.fromGitUrl(Uri gitUri);

//  Future install(Directory parentDir, {bool recursive: true});

  Future<ProjectGroup> childProjectGroup(ProjectGroupRef ref);

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

abstract class Project {
  Uri get gitUri;
  Directory get installDirectory;
  Future<Pubspec> get pubspec;
}

abstract class ProjectGroupMetaData {
//  Uri get gitUri;
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

enum ReleaseType { major, minor, patch }
