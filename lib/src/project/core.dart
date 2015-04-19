library devops.project.core;

import 'dart:async';
import 'dart:io';
import 'package:git/git.dart';
import '../spec/JefeSpec.dart';
import 'project.dart';

abstract class ProjectEntityReference<T extends ProjectEntity>
    extends ProjectEntityIdentifier {
  Future<T> get();
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
