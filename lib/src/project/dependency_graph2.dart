// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.dependency;

import 'dart:async';

import 'package:jefe/src/project/impl/jefe_project_impl.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:pubspec/pubspec.dart';

import 'project.dart';

Future<Set<JefeProject>> getRootProjects(Set<Project> projects) async =>
    (await getDependencyGraph(projects)).rootNodes;

/// Returns a [DependencyGraph] for the set of [projects]
@deprecated
Future<DependencyGraph> getDependencyGraph(Set<Project> projects) async =>
    new DependencyGraph._(await _determineDependencies(projects));

/// Represents a graph of dependencies between [Project]s
class DependencyGraph {

  Map<Project, _DependencyNode> _rootNodeMap = {};

  Map<Project, _DependencyNode> _nodeMap = {};

  // root nodes are those that nothing else depends on
  Set<JefeProject> get rootNodes =>
    _rootNodeMap.values.map((n) => n.toJefeProject()).toSet();

  DependencyGraph._(Set<_ProjectDependencies> dependencySet) {
    dependencySet.forEach((ds) => _add(ds.project, ds.directDependencies));
  }

  Option<JefeProject> getProjectByName(String projectName) =>


//  Option<JefeProject> getProjectByName(String projectName) =>

  void _add(Project project, Set<Project> dependencies) {
    final node = _getOrCreateNode(project);

    node._dependencies.addAll(dependencies.map(_getOrCreateNode));

    dependencies.forEach((p) => _rootNodeMap.remove(p));
  }

  _DependencyNode _getOrCreateNode(Project project) {
    var node = _nodeMap[project]; // TODO: is this possible?
    if (node == null) {
      node = new _DependencyNode(project, new Set<_DependencyNode>());
      _nodeMap[project] = node;
      _rootNodeMap[project] = node;
    }

    return node;
  }
}

class _ProjectDependencies {
  final Project project;
  final Set<Project> directDependencies;

  _ProjectDependencies(this.project, this.directDependencies);
}

class _DependencyNode implements _ProjectDependencies {
  final Project project;
  final Set<_DependencyNode> _dependencies;
  Set<Project> get directDependencies =>
      _dependencies.map((n) => n.project).toSet();

  _DependencyNode(this.project, this._dependencies);

  JefeProject toJefeProject() => new JefeProjectImpl.from(
      _dependencies.map((n) => n.toJefeProject()), project);
}

Future<Set<_ProjectDependencies>> _determineDependencies(
        Set<Project> projects) async =>
    (await Future.wait(projects.map((p) => _resolveDependencies(
            p, new Map.fromIterable(projects, key: (p) => p.name)))))
        .toSet();

Future<_ProjectDependencies> _resolveDependencies(
    Project project, Map<String, Project> projects) async {
  final PubSpec pubspec = project.pubspec;

  final dependencies = pubspec.allDependencies.keys
      .map((name) => projects[name])
      .where((v) => v != null)
      .toSet();

  return new _ProjectDependencies(project, dependencies);
}
