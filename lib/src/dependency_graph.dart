library devops.project.dependency;

import 'package:devops/src/project.dart';
import 'dart:async';
import 'package:devops/src/pubspec/pubspec_model.dart';
//import 'package:den_api/den_api.dart';

Future<DependencyGraph> getDependencyGraph(Set<Project> projects) async =>
    new DependencyGraph(await _determineDependencies(projects));

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

class DependencyGraph {
  // root nodes are those that nothing else depends on
  Set<_DependencyNode> get _rootNodes => _rootNodeMap.values.toSet();
  Map<Project, _DependencyNode> _rootNodeMap = {};

  Map<Project, _DependencyNode> _nodeMap = {};

  DependencyGraph(Set<_ProjectDependencies> dependencySet) {
    dependencySet.forEach((ds) => _add(ds.project, ds.dependencies));
  }

  void _add(Project project, Set<Project> dependencies) {
    final node = _getOrCreateNode(project);

    node._dependencies.addAll(dependencies.map(_getOrCreateNode));

    dependencies.forEach((p) => _rootNodeMap.remove(p));
  }

  void depthFirst(process(Project project, Iterable<Project> dependencies)) {
    _rootNodes.forEach((n) => n.depthFirst(process));
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
  Iterable<Project> get dependencies => _dependencies.map((n) => n.project);

  _DependencyNode(this.project);

  void depthFirst(process(Project project, Iterable<Project> dependencies)) {
    _dependencies.forEach((n) => n.depthFirst(process));
    process(project, dependencies);
  }
}

class _ProjectDependencies {
  final Project project;
  final Set<Project> dependencies;

  _ProjectDependencies(this.project, this.dependencies);
}
