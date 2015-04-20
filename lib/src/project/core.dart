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
