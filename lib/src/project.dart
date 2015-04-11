library devops.project;

import 'dart:async';
import 'dart:io';
import 'project_impl.dart';
import 'project_yaml.dart';
import 'package:path/path.dart' as p;

abstract class Ref<T> {
  String get name;
  Uri get gitUri;

  Future<T> install(Directory parentDir, {bool recursive: true});
}

abstract class ProjectRef implements Ref<Project> {
  factory ProjectRef.fromGitUrl(String name, Uri gitUri) = ProjectRefImpl;
}

abstract class ModuleRef implements Ref<Module> {
//  factory ModuleRef.fromGitUrl(Uri gitUri);
}

abstract class Project {
  Uri get gitUri;
  ProjectMetaData get metaData;
  Directory get installDirectory;

  static Future<Project> fromInstallDirectory(Directory installDirectory) =>
      loadProjectFromInstallDirectory(installDirectory);

//  factory Project.fromGitUrl(Uri gitUri);

//  Future install(Directory parentDir, {bool recursive: true});

  Future<Project> childProject(ProjectRef ref);

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

abstract class Module {
  Uri get gitUri;
  Directory get installDirectory;
}

abstract class ProjectMetaData {
//  Uri get gitUri;
  String get name;
  Iterable<ProjectRef> get childProjects;
  Iterable<ModuleRef> get modules;

  static Future<ProjectMetaData> fromDefaultProjectYamlFile(
          String projectDirectory) =>
      fromProjectYamlFile(p.join(projectDirectory, 'project.yaml'));

  static Future<ProjectMetaData> fromProjectYamlFile(String projectFile) =>
      readProjectYaml(new File(projectFile));
}

enum ReleaseType { major, minor, patch }
