// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.jefe;

import 'package:jefe/src/project/project.dart';
import 'dart:async';
import 'package:option/option.dart';
import 'package:collection/collection.dart';

/// A [Project] managed by Jefe
abstract class JefeProject extends Project {
  JefeProjectSet get directDependencies;
  Set<JefeProject> get indirectDependencies;
  Set<JefeProject> get allDependencies;

  /// Navigates the graph of [JefeProject] depthFirst such that those
  /// with no dependencies are returned first and those projects that are
  /// depended upon by other projects are returned before those projects
  Iterable<JefeProject> get depthFirst;

  Iterable<JefeProject> getDepthFirst(Set<JefeProject> visited);

  /// returns a [JefeProject] with matching name that is either this project
  /// or one of it's dependencies (direct or indirect)
  Option<JefeProject> getProjectByName(String projectName);

  /// Iterates over [depthFirst] invoking process for each
  Future processDepthFirst(
      process(JefeProject project, Iterable<JefeProject> dependencies));
}

class JefeProjectSet extends DelegatingSet<JefeProject> {
  JefeProjectSet(Set<JefeProject> base) : super(base);

  Option<JefeProject> getProjectByName(String projectName) =>
      map/*<Option<JefeProject>>*/((c) => c.getProjectByName(projectName))
          .firstWhere((o) => o is Some, orElse: () => const None());
}
