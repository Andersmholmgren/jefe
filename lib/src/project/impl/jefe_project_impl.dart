// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.jefe.impl;

import 'dart:io';

import 'package:jefe/src/project/impl/project_impl.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:logging/logging.dart';
import 'package:pubspec/pubspec.dart';
import 'dart:async';
import 'package:jefe/src/project/project.dart';
import 'package:option/option.dart';

Logger _log = new Logger('jefe.project.jefe.impl');

class JefeProjectImpl extends ProjectImpl implements JefeProject {
  @override
  final Set<JefeProject> directDependencies;

  @override
  Set<JefeProject> get allDependencies =>
      getDepthFirst(new Set<JefeProject>()).toSet();

  @override
  Set<JefeProject> get indirectDependencies =>
      allDependencies.difference(directDependencies);

  JefeProjectImpl(this.directDependencies, String gitUri,
      Directory installDirectory, PubSpec pubspec)
      : super(gitUri, installDirectory, pubspec);

  JefeProjectImpl.from(Set<JefeProject> directDependencies, Project project)
      : this(directDependencies, project.gitUri, project.installDirectory,
            project.pubspec);

  @override
  Iterable<JefeProject> get depthFirst =>
      directDependencies.expand /*<JefeProject>*/ (
          (n) => n.getDepthFirst(new Set<JefeProject>()));

//  /// The [JefeProject] for the given [projectName]
//  JefeProject forProject(String projectName) =>
//    depthFirst.firstWhere((pd) => pd.name == projectName);

  @override
  Future processDepthFirst(
      process(JefeProject project, Iterable<JefeProject> dependencies)) async {
    await Future.forEach(
        depthFirst, (JefeProject pd) => process(pd, pd.directDependencies));
  }

  Iterable<JefeProject> getDepthFirst(Set<JefeProject> visited) {
    final children = directDependencies.expand((n) => n.getDepthFirst(visited));

    Iterable us() sync* {
      if (!visited.contains((this))) {
        visited.add(this);
        yield this;
      }
    }

    return concat(<JefeProject>[children, us()]);
  }

  @override
  Option<JefeProject> getProjectByName(String projectName) =>
      name == projectName
          ? new Some<JefeProject>(this)
          : directDependencies
              .map((c) => c.getProjectByName(projectName))
              .firstWhere((o) => o is Some, orElse: () => const None());
}
