// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.dependency;

import 'project.dart';
import 'dart:async';
import 'package:quiver/iterables.dart';
import 'package:pubspec/pubspec.dart';

/// Returns a [DependencyGraph] for the set of [projects]
Future<DependencyGraph> getDependencyGraph(Set<Project> projects) async =>
    new DependencyGraph._(await _determineDependencies(projects));

/// Represents a graph of dependencies between [Project]s
class DependencyGraph {
  // root nodes are those that nothing else depends on
  Set<_DependencyNode> get _rootNodes => _rootNodeMap.values.toSet();
  Map<Project, _DependencyNode> _rootNodeMap = {};

  Map<Project, _DependencyNode> _nodeMap = {};

  DependencyGraph._(Set<_ProjectDependencies> dependencySet) {
    dependencySet.forEach((ds) => _add(ds.project, ds.directDependencies));
  }

  void _add(Project project, Set<Project> dependencies) {
    final node = _getOrCreateNode(project);

    node._dependencies.addAll(dependencies.map(_getOrCreateNode));

    dependencies.forEach((p) => _rootNodeMap.remove(p));
  }

  /// Navigates the graph of [ProjectDependencies] depthFirst such that those
  /// with no dependencies are returned first and those projects that are
  /// depended upon by other projects are returned before those projects
  Iterable<ProjectDependencies> get depthFirst {
    Set<Project> visited = new Set();
    return _rootNodes.expand((n) => n.getDepthFirst(visited));
  }

  /// The [ProjectDependencies] for the given [projectName]
  ProjectDependencies forProject(String projectName) =>
      depthFirst.firstWhere((pd) => pd.project.name == projectName);

  /// Iterates over [depthFirst] invoking process for each
  Future processDepthFirst(
      process(Project project, Iterable<Project> dependencies)) async {
    await Future.forEach(depthFirst,
        (ProjectDependencies pd) => process(pd.project, pd.directDependencies));
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

/// Represents a [Project] and the immediate projects it depends on
class _ProjectDependencies {
  final Project project;
  final Set<Project> directDependencies;

  _ProjectDependencies(this.project, this.directDependencies);
}

/// Represents a [Project] and all the projects it depends on directly and
/// indirectly
abstract class ProjectDependencies implements _ProjectDependencies {
  Project get project;
  Set<Project> get indirectDependencies;
  Set<Project> get allDependencies;
}

class _DependencyNode implements ProjectDependencies {
  final Project project;
  final Set<_DependencyNode> _dependencies = new Set();
  Iterable<Project> get directDependencies =>
      _dependencies.map((n) => n.project);

  _DependencyNode(this.project);

  Iterable<ProjectDependencies> getDepthFirst(Set<Project> visited) {
    final children = _dependencies.expand((n) => n.getDepthFirst(visited));

    Iterable us() sync* {
      if (!visited.contains((project))) {
        visited.add(project);
        yield this;
      }
    }

    return concat([children, us()]);
  }

  @override
  Set<Project> get allDependencies =>
      getDepthFirst(new Set()).map((pd) => pd.project).toSet();

  @override
  Set<Project> get indirectDependencies =>
      allDependencies.difference(directDependencies);
}

Future<Set<_ProjectDependencies>> _determineDependencies(
        Set<Project> projects) async =>
    (await Future.wait(projects.map((p) => _resolveDependencies(
        p, new Map.fromIterable(projects, key: (p) => p.name))))).toSet();

Future<_ProjectDependencies> _resolveDependencies(
    Project project, Map<String, Project> projects) async {
  final PubSpec pubspec = await project.pubspec;
  final dependencies = pubspec.dependencies.keys
      .map((name) => projects[name])
      .where((v) => v != null)
      .toSet();

  return new _ProjectDependencies(project, dependencies);
}
