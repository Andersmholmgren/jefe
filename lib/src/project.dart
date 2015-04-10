library devops.project;
import 'dart:async';
import 'dart:io';
import 'project_impl.dart';


abstract class Ref<T> {
  Uri get gitUri;

  Future<T> fetch();
}

abstract class ProjectRef implements Ref<Project> {
  factory ProjectRef.fromGitUrl(Uri gitUri) = ProjectRefImpl;
}

abstract class ModuleRef implements Ref<Module> {
  factory ModuleRef.fromGitUrl(Uri gitUri);
}

abstract class Project {
  String get name;
  Iterable<ProjectRef> get childProjects;
  Iterable<ModuleRef> get modules;

  factory Project.fromProjectYaml(String projectFile);
  factory Project.fromGitUrl(Uri gitUri);

  Future install(Directory parentDir, {bool recursive: true});
  Future update({bool recursive: true});
  Future setupForDev({bool recursive: true});
  Future release({bool recursive: true});

}

class Module {

}