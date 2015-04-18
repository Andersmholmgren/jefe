library devops.project.operations.docker.impl;

import 'package:logging/logging.dart';
import 'package:devops/src/project.dart';
import 'package:devops/src/project_operations/project_command.dart';
import 'package:devops/src/project_operations/docker_commands.dart';
import 'package:devops/src/dockerfile/dockerfile.dart';
//import 'package:path/path.dart' as p;
import 'package:devops/src/pubspec/dependency.dart';
import 'package:devops/src/dependency_graph.dart';
import 'dart:io';

Logger _log = new Logger('devops.project.operations.docker.impl');

class DockerCommandsImpl implements DockerCommands {
  @override
  ProjectDependencyGraphCommand generateDockerfile(
          Iterable<String> topLevelProjectNames, Directory outputDirectory) =>
      dependencyGraphCommand('generate Dockerfile',
          (DependencyGraph graph) async {
    final projectDependencies = topLevelProjectNames.map(graph.forProject);

    final allDependencies = projectDependencies
        .expand((ProjectDependencies pd) => pd.dependencies)
        .toSet();

    final topLevelProjects = projectDependencies.map((pd) => pd.project);

    final depMap =
        new Map.fromIterable(allDependencies, key: (project) => project.name);

    final pathDependentProjects = topLevelProjects.expand((Project project) {
      final deps = project.pubspec.dependencies;
      final pathKeys = deps.keys.where(
          (key) => deps[key] is PathReference && depMap.keys.contains(key));
      return pathKeys.map((key) => depMap[key]);
    }).toSet();

    final dockerfile = new Dockerfile();

    pathDependentProjects.forEach((prj) {
      final dir = prj.installDirectory.path;
      dockerfile.add(dir, dir);
    });

    topLevelProjects.forEach((prj) {
      final dir = prj.installDirectory.path;
      dockerfile.add(dir, dir);
    });

    await dockerfile.save(outputDirectory);
  });
}
