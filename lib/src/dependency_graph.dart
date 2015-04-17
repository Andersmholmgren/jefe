library devops.project.dependency;

import 'package:devops/src/project.dart';
import 'dart:async';
import 'package:devops/src/pubspec/pubspec.dart';
import 'package:quiver/iterables.dart';

Future<DependencyGraph> getDependencyGraph(Set<Project> projects) async =>
    new DependencyGraph(await _determineDependencies(projects));

Future<Set<ProjectDependencies>> _determineDependencies(
        Set<Project> projects) async =>
    (await Future.wait(projects.map((p) => _resolveDependencies(
        p, new Map.fromIterable(projects, key: (p) => p.name))))).toSet();

Future<ProjectDependencies> _resolveDependencies(
    Project project, Map<String, Project> projects) async {
  final PubSpec pubspec = await project.pubspec;
  final dependencies = pubspec.dependencies.keys
      .map((name) => projects[name])
      .where((v) => v != null)
      .toSet();

  return new ProjectDependencies(project, dependencies);
}

class DependencyGraph {
  // root nodes are those that nothing else depends on
  Set<_DependencyNode> get _rootNodes => _rootNodeMap.values.toSet();
  Map<Project, _DependencyNode> _rootNodeMap = {};

  Map<Project, _DependencyNode> _nodeMap = {};

  DependencyGraph(Set<ProjectDependencies> dependencySet) {
    dependencySet.forEach((ds) => _add(ds.project, ds.dependencies));
  }

  void _add(Project project, Set<Project> dependencies) {
    final node = _getOrCreateNode(project);

    node._dependencies.addAll(dependencies.map(_getOrCreateNode));

    dependencies.forEach((p) => _rootNodeMap.remove(p));
  }

  Future processDepthFirst(
      process(Project project, Iterable<Project> dependencies)) async {
    await Future.forEach(depthFirst,
        (ProjectDependencies pd) => process(pd.project, pd.dependencies));
  }

  Iterable<ProjectDependencies> get depthFirst {
    Set<Project> visited = new Set();
    return _rootNodes.expand((n) => n.getDepthFirst(visited));
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

  Future depthFirst(process(Project project, Iterable<Project> dependencies),
      Set<Project> visited) async {
    await Future.forEach(_dependencies, (n) => n.depthFirst(process, visited));
    if (!visited.contains((project))) {
      visited.add(project);
      await process(project, dependencies);
    }
  }

  Iterable<ProjectDependencies> getDepthFirst(Set<Project> visited) {
    final children = _dependencies.expand((n) => n.getDepthFirst(visited));

    Iterable us() sync* {
      if (!visited.contains((project))) {
        visited.add(project);
        yield new ProjectDependencies(project, dependencies.toSet());
      }
    }

    return concat([children, us()]);
  }
}

class ProjectDependencies {
  final Project project;
  final Set<Project> dependencies;

  ProjectDependencies(this.project, this.dependencies);
}
