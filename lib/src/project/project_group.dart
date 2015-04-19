library devops.project.group;

import 'dart:async';
import 'dart:io';
import 'impl/project_group_impl.dart';
import '../spec/JefeSpec.dart';
import 'project.dart';
import 'core.dart';

abstract class ProjectGroupReference
    implements ProjectEntityReference<ProjectGroup> {}

abstract class ProjectGroup extends ProjectEntity implements ProjectSource {
  ProjectGroupIdentifier get id;

  static Future<ProjectGroup> install(Directory parentDir, String gitUri,
      {String name}) => ProjectGroupImpl.install(parentDir, gitUri, name: name);

  static Future<ProjectGroup> load(Directory installDirectory) =>
      ProjectGroupImpl.load(installDirectory);

  // the directory that is the container for the group.
  // Typically named <groupName>_root
  Directory get containerDirectory;

  Future<Set<Project>> get allProjects;

  Future processDependenciesDepthFirst(
      process(Project project, Iterable<Project> dependencies));
}
