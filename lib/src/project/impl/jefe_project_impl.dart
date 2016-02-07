// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.jefe.impl;

import 'dart:io';

import 'package:jefe/src/project/impl/project_impl.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:logging/logging.dart';
import 'package:pubspec/pubspec.dart';

Logger _log = new Logger('jefe.project.jefe.impl');

class JefeProjectImpl extends ProjectImpl implements JefeProject {
  @override
  final Set<JefeProject> directDependencies;

  @override
  Set<JefeProject> get allDependencies => null;

  @override
  Set<JefeProject> get indirectDependencies =>
      allDependencies.difference(directDependencies);

  JefeProjectImpl(this.directDependencies, String gitUri,
      Directory installDirectory, PubSpec pubspec)
      : super(gitUri, installDirectory, pubspec);
}
