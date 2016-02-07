// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.jefe.impl;

import 'dart:async';
import 'dart:io';

import 'package:jefe/src/project/impl/project_impl.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project/project.dart';
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:pubspec/pubspec.dart';

Logger _log = new Logger('jefe.project.jefe.impl');

class JefeProjectImpl extends ProjectImpl
    with JefeProjectGraphMixin
    implements JefeProject, JefeProjectGraph {
  @override
  final JefeProjectSet directDependencies;

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
  Iterable<JefeProject> getDepthFirst(Set<JefeProject> visited) {
    final children = directDependencies.getDepthFirst(visited);

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
          : directDependencies.getProjectByName(projectName);
}
