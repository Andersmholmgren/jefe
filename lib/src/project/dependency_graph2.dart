// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.dependency;

import 'dart:async';

import 'package:jefe/src/project/impl/jefe_project_impl.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:pubspec/pubspec.dart';

import 'project.dart';

/// Returns a [DependencyGraph] for the set of [projects]
Future<DependencyGraph> getDependencyGraph(Set<Project> projects) async =>
    new DependencyGraph._(await _determineDependencies(projects));

/// Represents a graph of dependencies between [Project]s
class DependencyGraph {
  // root nodes are those that nothing else depends on
  Set<JefeProject> get rootNodes =>
      _rootNodeMap.values.map((n) => n.toJefeProject()).toSet();

  Map<Project, _DependencyNode> _rootNodeMap = {};

  Map<Project, _DependencyNode> _nodeMap = {};

  DependencyGraph._(Set<_DependencyNode> dependencySet) {
    dependencySet.forEach((ds) => _add(ds.project, ds.directDependencies));
  }

  void _add(Project project, Set<Project> dependencies) {
    final node = _getOrCreateNode(project);

    node._dependencies.addAll(dependencies.map(_getOrCreateNode));

    dependencies.forEach((p) => _rootNodeMap.remove(p));
  }

  _DependencyNode _getOrCreateNode(Project project) {
    var node = _nodeMap[project]; // TODO: is this possible?
    if (node == null) {
      node = new _DependencyNode(project);
      _nodeMap[project] = node;
      _rootNodeMap[project] = node;
    }

    return node;
  }
}

class _DependencyNode {
  final Project project;
  final Set<_DependencyNode> _dependencies = new Set();
  Iterable<Project> get directDependencies =>
      _dependencies.map((n) => n.project);

  _DependencyNode(this.project);

  JefeProject toJefeProject() => new JefeProjectImpl.from(
      _dependencies.map((n) => n.toJefeProject()), project);

//  Iterable<ProjectDependencies> getDepthFirst(Set<Project> visited) {
//    final children = _dependencies.expand((n) => n.getDepthFirst(visited));
//
//    Iterable us() sync* {
//      if (!visited.contains((project))) {
//        visited.add(project);
//        yield this;
//      }
//    }
//
//    return concat([children, us()]);
//  }

//  @override
//  Set<Project> get allDependencies =>
//      getDepthFirst(new Set()).map((pd) => pd.project).toSet();

//  @override
//  Set<Project> get indirectDependencies =>
//      allDependencies.difference(directDependencies);
}

Future<Set<_DependencyNode>> _determineDependencies(
        Set<Project> projects) async =>
    (await Future.wait(projects.map((p) => _resolveDependencies(
            p, new Map.fromIterable(projects, key: (p) => p.name)))))
        .toSet();

Future<_DependencyNode> _resolveDependencies(
    Project project, Map<String, Project> projects) async {
  final PubSpec pubspec = project.pubspec;

  final dependencies = pubspec.allDependencies.keys
      .map((name) => projects[name])
      .where((v) => v != null)
      .toSet();

  return new _DependencyNode(project, dependencies);
}
