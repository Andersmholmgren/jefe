library devops.project.dependency;

import 'package:devops/src/project.dart';
import 'dart:async';
import 'package:den_api/den_api.dart';

class ProjectDependencies {
  final Project project;
  final Set<Project> dependencies;

  ProjectDependencies(this.project, this.dependencies);
}

Future<Set<ProjectDependencies>> determineDependencies(
        Set<Project> projects) async =>
    (await Future.wait(projects.map((p) => _resolveDependencies(
        p, new Map.fromIterable(projects, key: (p) => p.name))))).toSet();

Future<ProjectDependencies> _resolveDependencies(
    Project project, Map<String, Project> projects) async {
  final Pubspec pubspec = await project.pubspec;
  final dependencies = pubspec.dependencies.keys
      .map((name) => projects[name])
      .where((v) => v != null)
      .toSet();

  return new ProjectDependencies(project, dependencies);
}

class DependencyGraph {
  // root nodes are those that nothing else depends on
  Set<DependencyNode> get rootNodes => _rootNodeMap.values.toSet();
  Map<Project, DependencyNode> _rootNodeMap = {};

  Map<Project, DependencyNode> _nodeMap = {};

  void add(Project project, Set<Project> dependencies) {
    final node = _getOrCreateNode(project);

    node.dependencies.addAll(dependencies.map(_getOrCreateNode));

    dependencies.forEach((p) => _rootNodeMap.remove(p));
  }

  DependencyNode _getOrCreateNode(Project project) {
    var node = _nodeMap[project]; // TODO: is this possible?
    if (node == null) {
      node = new DependencyNode(project);
      _nodeMap[project] = node;
      _rootNodeMap[project] = node;
    }

    return node;
  }
}
class DependencyNode {
  final Project project;
  final List<DependencyNode> dependencies = [];

  DependencyNode(this.project);
}
