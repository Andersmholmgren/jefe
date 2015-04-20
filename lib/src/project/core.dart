// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.core;

import 'dart:async';
import 'dart:io';
import 'package:git/git.dart';
import '../spec/JefeSpec.dart';
import 'project.dart';

/// A reference to a [ProjectEntity]. The actual entity is fetched via [get]
abstract class ProjectEntityReference<T extends ProjectEntity>
    extends ProjectEntityIdentifier {

  /// retrieve the entity
  Future<T> get();
}

/// an entity that is a member of a [ProjectGroup]. This includes both
/// [Project]s and [ProjectGroup]s
abstract class ProjectEntity {

  /// The name of the entity
  String get name;

  /// the Uri of the Git repository for this entity
  String get gitUri;

  /// Retrieves a [GitDir] for the entity
  Future<GitDir> get gitDir;

  /// Where the entity installed locally
  Directory get installDirectory;
}
