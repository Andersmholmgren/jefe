library devops.project.group;

import 'dart:async';
import 'dart:io';
import 'impl/project_group_impl.dart';
import '../spec/JefeSpec.dart';
import 'project.dart';
import 'core.dart';

abstract class ProjectGroupReference
    implements ProjectEntityReference<ProjectGroup> {}

/// Represents a group of related [Project]s. These projects are managed as
/// a unit and typically have dependencies between them.
abstract class ProjectGroup extends ProjectEntity implements ProjectSource {
  ProjectGroupIdentifier get id;

  /// Install a [ProjectGroup] plus all its [Project]s and child [ProjectGroup]s
  /// recursively.
  /// The [gitUri] is the git repository that contains the metadata file for
  /// the project group.
  /// The group will be installed as a child of the [parentDirectory]
  static Future<ProjectGroup> install(Directory parentDirectory, String gitUri,
          {String name}) =>
      ProjectGroupImpl.install(parentDirectory, gitUri, name: name);

  static Future<ProjectGroup> load(Directory installDirectory) =>
      ProjectGroupImpl.load(installDirectory);

  /// References to the projects contained directly within this group.
  /// This excludes those contained in child groups
  Iterable<ProjectReference> get projects;

  /// References to [ProjectGroup]s that are direct children of this group
  Iterable<ProjectGroupReference> get childGroups;
}
