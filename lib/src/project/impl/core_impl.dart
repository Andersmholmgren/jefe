// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.core.impl;

import 'dart:async';
import 'package:git/git.dart';
import 'package:logging/logging.dart';
import 'dart:io';
import 'package:jefe/src/project/core.dart';

Logger _log = new Logger('jefe.project.impl');

abstract class ProjectEntityImpl implements ProjectEntity {
  final String gitUri;
  final Directory installDirectory;

  ProjectEntityImpl(this.gitUri, this.installDirectory);

  @override
  Future<GitDir> get gitDir {
//    print('--- loading git dir from ${installDirectory.path}');
    return GitDir.fromExisting(installDirectory.path);
  }
}
