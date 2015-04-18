library devops.project.operations.docker.impl;

import 'package:logging/logging.dart';
import 'package:devops/src/project.dart';
import 'package:devops/src/project_operations/project_command.dart';
import 'package:devops/src/project_operations/docker_commands.dart';
import 'package:devops/src/dockerfile/dockerfile.dart';
import 'package:path/path.dart' as p;
import 'package:devops/src/pubspec/dependency.dart';
import 'package:devops/src/dependency_graph.dart';
import 'dart:io';
import 'package:quiver/iterables.dart';

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

  ProjectDependencyGraphCommand generateDockerfile2(String serverProjectName,
          String clientProjectName, Directory outputDirectory) =>
      dependencyGraphCommand('generate Dockerfile',
          (DependencyGraph graph) async {
    final serverProjectDeps = graph.forProject(serverProjectName);
    final clientProjectDeps = graph.forProject(clientProjectName);

    final allDependencies = concat(
            [serverProjectDeps.dependencies, clientProjectDeps.dependencies])
        .toSet();

    final topLevelProjects = [
      serverProjectDeps.project,
      clientProjectDeps.project
    ];

    final depMap =
        new Map.fromIterable(allDependencies, key: (project) => project.name);

    final pathDependentProjects = topLevelProjects.expand((Project project) {
      final deps = project.pubspec.dependencies;
      final pathKeys = deps.keys.where(
          (key) => deps[key] is PathReference && depMap.keys.contains(key));
      return pathKeys.map((key) => depMap[key]);
    }).toSet();

    final dockerfile = new Dockerfile();

    dockerfile.from('google/dart', tag: '1.9.1');

    pathDependentProjects.forEach((prj) {
      final dir = prj.installDirectory.path;
      dockerfile.addDir(dir, dir);
    });

    _addTopLevelProjectFiles(dockerfile, serverProjectDeps);
    _addTopLevelProjectFiles(dockerfile, clientProjectDeps);
    final serverMain = p.join(
        serverProjectDeps.project.installDirectory.path, 'bin/server.dart');

    // TODO: pass in
    final Map<String, dynamic> environment = {'USE_PUB_SERVE_IN_DEV': false};
    dockerfile.envs(environment);

    // TODO: pass in
    final exposePorts = [8080, 8181, 5858];
    dockerfile.expose(exposePorts);

    // TODO: pass in
    final entryPointOptions = ["--debug:5858/0.0.0.0"];
    dockerfile.entryPoint('/usr/bin/dart',
        args: concat([entryPointOptions, [serverMain]]));

    await dockerfile.save(outputDirectory);
  });

  _addTopLevelProjectFiles(
      Dockerfile dockerfile, ProjectDependencies topLevelProjectDeps) {
    final dir = topLevelProjectDeps.project.installDirectory;
    final dirPath = dir.path;

    final pubspecYaml = p.join(dirPath, 'pubspec.yaml');
    dockerfile.add(pubspecYaml, pubspecYaml);

    final pubspecLock = p.join(dirPath, 'pubspec.lock');
    dockerfile.add(pubspecLock, pubspecLock);

    dockerfile.workDir(dirPath);
    dockerfile.run('pub', args: ['get']);

    dockerfile.addDir(dirPath, dirPath);
    dockerfile.run('pub', args: ['get', '--offline']);
  }
}

/*
ADD gitbacklog/gitbacklog_client/pubspec.yaml /app/client/
ADD gitbacklog/gitbacklog_client/pubspec.lock /app/client/

WORKDIR /app/client
RUN pub get

ADD gitbacklog/gitbacklog_client /app/client/
WORKDIR /app/client
RUN pub get --offline
RUN pub build



ADD gitbacklog/gitbacklog_server/pubspec.yaml /app/server/
ADD gitbacklog/gitbacklog_server/pubspec.lock /app/server/

WORKDIR /app/server
RUN pub get

ADD gitbacklog/gitbacklog_server /app/server/
WORKDIR /app/server
RUN pub get --offline

 */
