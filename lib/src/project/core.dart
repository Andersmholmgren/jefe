// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.core;

import 'dart:async';
import 'dart:io';
import 'package:git/git.dart';
import '../spec/JefeSpec.dart';
import 'project.dart';

abstract class ProjectEntityReference<T extends ProjectEntity>
    extends ProjectEntityIdentifier {
  Future<T> get();
}

/// an entity that is a member of a [ProjectGroup]. This includes both
/// [Project]s and [ProjectGroup]s
abstract class ProjectEntity {
  String get name;
  String get gitUri;
  Future<GitDir> get gitDir;
  Directory get installDirectory;
}

@deprecated // TODO: Does this still provide any value beyond ProjectGroup??
abstract class ProjectSource {
  /// All [Project]s contained either directly within this [ProjectGroup] or
  /// as within child groups recursively
  Future<Iterable<Project>> get allProjects;

  /// The directory that acts as the container for all the groups project
  /// and metadata directories. These are named with a '_root' suffix
  Directory get containerDirectory;
}
