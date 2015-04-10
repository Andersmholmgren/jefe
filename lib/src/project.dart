library devops.project;
import 'dart:async';

abstract class Project {
  Iterable<Project> get childProjects;
  Iterable<Module> get modules;

  factory Project.fromProjectYaml(String projectFile);
  factory Project.fromGitUrl(Uri gitUri);

  Future install({bool recursive: true});
  Future update({bool recursive: true});
  Future setupForDev({bool recursive: true});
  Future release({bool recursive: true});

}

class Module {

}