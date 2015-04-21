// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.docker.impl;

import 'package:logging/logging.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:jefe/src/project_commands/docker_commands.dart';
import 'package:dockerfile/dockerfile.dart';
import 'package:path/path.dart' as p;
import 'package:jefe/src/project/dependency_graph.dart';
import 'dart:io';
import 'package:quiver/iterables.dart';
import 'dart:async';
import 'package:jefe/src/git/git.dart';
import 'package:pubspec/pubspec.dart';

Logger _log = new Logger('jefe.project.commands.docker.impl');

class DockerCommandsImpl implements DockerCommands {
  ProjectDependencyGraphCommand generateDockerfile(
      String serverProjectName, String clientProjectName,
      {Directory outputDirectory, String dartVersion: 'latest',
      Map<String, dynamic> environment: const {},
      Iterable<int> exposePorts: const [],
      Iterable<String> entryPointOptions: const [],
      bool omitClientWhenPathDependencies: true, bool setupForPrivateGit: true,
      String targetRootPath: '/app'}) => dependencyGraphCommand(
          'generate Dockerfile',
          (DependencyGraph graph, Directory rootDirectory, _) async {
    final serverProjectDeps = graph.forProject(serverProjectName);
    final clientProjectDeps = graph.forProject(clientProjectName);

    final serverPathDependentProjects =
        _pathDependentProjects(serverProjectDeps);
    final clientPathDependentProjects =
        _pathDependentProjects(clientProjectDeps);

    final omitClient = omitClientWhenPathDependencies &&
        clientPathDependentProjects.isNotEmpty;

    final pathDependentProjects = omitClient
        ? serverPathDependentProjects
        : concat([serverPathDependentProjects, clientPathDependentProjects])
            .toSet();

//    if (serverGitRef != null)

    final pathHandler = new _PathHandler(
        rootDirectory.path, targetRootPath, pathDependentProjects.isNotEmpty);

    final dockerfile = new Dockerfile();

    dockerfile.from('google/dart', tag: dartVersion);

    _setupForPrivateGit(setupForPrivateGit, dockerfile);

    pathDependentProjects.forEach((prj) {
      final dir = prj.installDirectory.path;
      dockerfile.addDir(
          pathHandler.sourcePath(dir), pathHandler.targetPath(dir));
    });

    _addTopLevelProjectFiles(dockerfile, serverProjectDeps, pathHandler);
    if (!omitClient) {
      _addTopLevelProjectFiles(dockerfile, clientProjectDeps, pathHandler);
      dockerfile.run('pub', args: ['build']);
    }

    dockerfile.envs(environment);

    dockerfile.expose(exposePorts);

    dockerfile.cmd([]);

    final serverMain = p.join(
        serverProjectDeps.project.installDirectory.path, 'bin/server.dart');

    dockerfile.entryPoint('/usr/bin/dart',
        args: concat(
            [entryPointOptions, [pathHandler.targetPath(serverMain)]]));

    final saveDirectory =
        outputDirectory != null ? outputDirectory : rootDirectory;
    await dockerfile.save(saveDirectory);
  });

  ProjectDependencyGraphCommand generateProductionDockerfile(
      String serverProjectName, String clientProjectName, {String serverGitRef,
      String clientGitRef, Directory outputDirectory,
      String dartVersion: 'latest', Map<String, dynamic> environment: const {},
      Iterable<int> exposePorts: const [],
      Iterable<String> entryPointOptions: const [],
      String targetRootPath: '/app'}) => dependencyGraphCommand(
          'generate Dockerfile',
          (DependencyGraph graph, Directory rootDirectory, _) async {
    final serverProjectDeps = graph.forProject(serverProjectName);
    final clientProjectDeps = graph.forProject(clientProjectName);

    final pathHandler =
        new _PathHandler(rootDirectory.path, targetRootPath, false);

    final dockerfile = new Dockerfile();

    dockerfile.from('google/dart', tag: dartVersion);

    _setupForPrivateGit(true, dockerfile);

    await _cloneTopLevelProject(
        dockerfile, serverProjectDeps, serverGitRef, pathHandler);
    await _cloneTopLevelProject(
        dockerfile, clientProjectDeps, clientGitRef, pathHandler);
    dockerfile.run('pub', args: ['build']);

    dockerfile.envs(environment);

    dockerfile.expose(exposePorts);

    dockerfile.cmd([]);

    final serverMain = p.join(
        serverProjectDeps.project.installDirectory.path, 'bin/server.dart');

    dockerfile.entryPoint('/usr/bin/dart',
        args: concat(
            [entryPointOptions, [pathHandler.targetPath(serverMain)]]));

    final saveDirectory =
        outputDirectory != null ? outputDirectory : rootDirectory;
    await dockerfile.save(saveDirectory);
  });

  void _addTopLevelProjectFiles(Dockerfile dockerfile,
      ProjectDependencies topLevelProjectDeps, _PathHandler pathHandler) {
    final addHelper = new _AddHelper(pathHandler, dockerfile);
    final dir = topLevelProjectDeps.project.installDirectory;
    final dirPath = dir.path;

    final pubspecYaml = p.join(dirPath, 'pubspec.yaml');
    addHelper.add(pubspecYaml);

    final pubspecLock = p.join(dirPath, 'pubspec.lock');
    addHelper.add(pubspecLock);

    dockerfile.workDir(pathHandler.targetPath(dirPath));
    dockerfile.run('pub', args: ['get']);

    addHelper.addDir(dirPath);
    dockerfile.run('pub', args: ['get', '--offline']);
  }

  Future _cloneTopLevelProject(Dockerfile dockerfile,
      ProjectDependencies topLevelProjectDeps, String gitRef,
      _PathHandler pathHandler) async {
    final ref = gitRef != null
        ? gitRef
        : (await gitCurrentTagName(await topLevelProjectDeps.project.gitDir))
            .get();

    final dir = topLevelProjectDeps.project.installDirectory;
    final dirPath = dir.path;

    final targetPath = pathHandler.targetPath(dirPath);
    dockerfile.run('git',
        args: [
      'clone',
      '-q',
      '-b',
      ref,
      topLevelProjectDeps.project.gitUri,
      targetPath
    ]);
    dockerfile.workDir(targetPath);
//    dockerfile.run('git', args: ['checkout', '-q', ref]);

    dockerfile.run('pub', args: ['get']);
  }

  Set<Project> _pathDependentProjects(ProjectDependencies projectDependencies) {
    final depMap = new Map.fromIterable(projectDependencies.dependencies,
        key: (project) => project.name);

    final deps = projectDependencies.project.pubspec.dependencies;
    final pathKeys = deps.keys.where(
        (key) => deps[key] is PathReference && depMap.keys.contains(key));

    return pathKeys.map((key) => depMap[key]).toSet();
  }

  void _setupForPrivateGit(bool setupForPrivateGit, Dockerfile dockerfile) {
    if (setupForPrivateGit) {
      // TODO: ssh required for git protocol. Is there a smaller package?
      // Is there any security issues to adding this?
      dockerfile.run('apt-get', args: ['update']);
      dockerfile.run('apt-get', args: ['install', '-y', 'ssh']);
      dockerfile.add('id_rsa', '/root/.ssh/id_rsa');
      dockerfile.run('ssh-keyscan',
          args: ['bitbucket.org', '>>', '/root/.ssh/known_hosts']);
      dockerfile.run('ssh-keyscan',
          args: ['github.com', '>>', '/root/.ssh/known_hosts']);
    }
  }
}

class _PathHandler {
  final String rootPath;
  final String targetRootPath;
  final bool hasPathDependencies;

  _PathHandler(this.rootPath, this.targetRootPath, this.hasPathDependencies);

  String sourcePath(String source) {
    return p.relative(source, from: rootPath);
  }

  String targetPath(String source) {
    if (hasPathDependencies) {
      return source;
    }

    final subPath = p.relative(source, from: rootPath);
    return p.join(targetRootPath, subPath);
  }
}

class _AddHelper {
  final _PathHandler pathHandler;
  final Dockerfile dockerfile;
  _AddHelper(this.pathHandler, this.dockerfile);

  void add(String path) {
    dockerfile.add(pathHandler.sourcePath(path), pathHandler.targetPath(path));
  }
  void addDir(String path) {
    dockerfile.addDir(
        pathHandler.sourcePath(path), pathHandler.targetPath(path));
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
