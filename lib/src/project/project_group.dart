// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.group;

import 'dart:async';
import 'dart:io';
import 'impl/project_group_impl.dart';
import '../spec/jefe_spec.dart';
import 'project.dart';
import 'core.dart';
import 'package:jefe/src/project/dependency_graph.dart';

abstract class ProjectGroupReference
    implements ProjectEntityReference<ProjectGroup> {}

/// Represents a group of related [Project]s. These projects are managed as
/// a unit and typically have dependencies between them.
abstract class ProjectGroup extends ProjectEntity {
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

  /// Will git pull any existing project groups, and install any that are missing
  static Future<ProjectGroup> init(Directory parentDir, String gitUri,
          {String name}) =>
      ProjectGroupImpl.init(parentDir, gitUri, name: name);

  /// References to the [Project]s contained directly within this group.
  /// This excludes those contained in child groups
  Iterable<ProjectReference> get projects;

  /// References to [ProjectGroup]s that are direct children of this group
  Iterable<ProjectGroupReference> get childGroups;

  /// All [Project]s contained either directly within this [ProjectGroup] or
  /// as within child groups recursively
  Future<Iterable<Project>> get allProjects;

  /// Creates a graph of the dependency relationships for [allProjects]
  @deprecated
  Future<DependencyGraph> get dependencyGraph;

  /// The directory that acts as the container for all the groups project
  /// and metadata directories. These are named with a '_root' suffix
  Directory get containerDirectory;
}
