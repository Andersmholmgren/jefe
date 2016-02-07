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

abstract class JefeProjectGraph {
  JefeProjectSet get directDependencies;

  Iterable<JefeProject> get depthFirst;

  Iterable<JefeProject> getDepthFirst(Set<JefeProject> visited);

  Future processDepthFirst(
      process(JefeProject project, Iterable<JefeProject> dependencies));
}

class JefeProjectSet extends DelegatingSet<JefeProject>
    with JefeProjectGraphMixin
    implements JefeProjectGraph {
  JefeProjectSet(Set<JefeProject> base) : super(base);

  JefeProjectSet get directDependencies => this;

  Option<JefeProject> getProjectByName(String projectName) =>
      map/*<Option<JefeProject>>*/((c) => c.getProjectByName(projectName))
          .firstWhere((o) => o is Some, orElse: () => const None());

  Iterable<JefeProject> getDepthFirst(Set<JefeProject> visited) =>
      expand/*<JefeProject>*/((n) => n.getDepthFirst(visited));
}

abstract class JefeProjectGraphMixin extends JefeProjectGraph {
//  Option<JefeProject> getProjectByName(String projectName) =>
//      map/*<Option<JefeProject>>*/((c) => c.getProjectByName(projectName))
//          .firstWhere((o) => o is Some, orElse: () => const None());

  Iterable<JefeProject> get depthFirst {
    return getDepthFirst(new Set<JefeProject>());
  }

  Future processDepthFirst(
      process(JefeProject project, Iterable<JefeProject> dependencies)) async {
    await Future.forEach(
        depthFirst, (JefeProject p) => process(p, p.directDependencies));
  }
}
