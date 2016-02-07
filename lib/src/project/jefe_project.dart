// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.jefe;

import 'dart:async';

import 'package:jefe/src/project/project.dart';
import 'package:option/option.dart';

/// A [Project] managed by Jefe
abstract class JefeProject extends Project implements JefeProjectGraph {
  JefeProjectSet get directDependencies;
  Set<JefeProject> get indirectDependencies;
  Set<JefeProject> get allDependencies;
}

/// Some function applied to a [JefeProject]
typedef Future<T> ProjectFunction<T>(JefeProject project);

typedef bool ProjectFilter(Project p);

bool _noOpFilter(Project p) => true;

/// A graph of [JefeProject] ordered by their dependencies
abstract class JefeProjectGraph {
  /// Navigates the graph of [JefeProject] depthFirst such that those
  /// with no dependencies are returned first and those projects that are
  /// depended upon by other projects are returned before those projects
  Iterable<JefeProject> get depthFirst;

  Iterable<JefeProject> getDepthFirst(Set<JefeProject> visited);

  /// returns a [JefeProject] with matching name that is either this project
  /// or one of it's dependencies (direct or indirect)
  Option<JefeProject> getProjectByName(String projectName);

  /// Iterates over [depthFirst] invoking [command] for each
  Future/*<T>*/ processDepthFirst/*<T>*/(ProjectFunction/*<T>*/ command);

  /// Invokes [command] on this project and all reachable dependencies.
  ///
  /// An optional [filter] can be provided to limit which projects the [command]
  /// is executed on.
  Future/*<T>*/ processAllConcurrently/*<T>*/(ProjectFunction/*<T>*/ command,
      {ProjectFilter filter: _noOpFilter});

  /// Invokes [command] on this project and all reachable dependencies
  Future/*<T>*/ processAllSerially/*<T>*/(ProjectFunction/*<T>*/ command,
      {ProjectFilter filter: _noOpFilter});
}

/// A [Set] of [JefeProject] that supports [JefeProjectGraph] operations
abstract class JefeProjectSet implements Set<JefeProject>, JefeProjectGraph {}
