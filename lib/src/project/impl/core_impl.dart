// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.core.impl;

import 'dart:async';
import 'dart:io';

import 'package:git/git.dart';
import 'package:jefe/src/project/core.dart';
import 'package:logging/logging.dart';

Logger _log = new Logger('jefe.project.impl');

abstract class ProjectEntityImpl implements ProjectEntity {
  final String gitUri;
  final Directory installDirectory;

  ProjectEntityImpl(this.gitUri, this.installDirectory);

  GitDir _gitDir;

  @override
  Future<GitDir> get gitDir async =>
      _gitDir ??= await GitDir.fromExisting(installDirectory.path);
}
