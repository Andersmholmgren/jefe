// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.docker.impl;

import 'dart:async';
import 'dart:io';

import 'package:dockerfile/dockerfile.dart';
import 'package:jefe/src/git/git.dart';
import 'package:jefe/src/project/docker_commands.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project/project.dart';
//import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:pubspec/pubspec.dart';
import 'package:quiver/iterables.dart';

//Logger _log = new Logger('jefe.project.commands.docker.impl');

DockerCommands createDockerCommands(
    JefeProjectGraph graph, Directory rootDirectory,
    {bool multiProject: true}) {
  // no distinction between multi and single project docker. Always operates
  // at one level
  return new DockerCommandsMultiProjectImpl(graph, rootDirectory);
}

//abstract class DockerCommandsImpl implements DockerCommands {
//  factory DockerCommandsImpl(JefeProjectGraph graph,
//      {bool multiProject: true}) {
//    // no distinction between multi and single project docker. Always operates
//    // at one level
//    return new DockerCommandsMultiProjectImpl(graph);
////    return multiProject
////      ? new _DockerCommandsMultiProjectImpl(graph)
////      : throw new ArgumentError('no single project version of')
//  }
//}

//class DockerCommandsSingleProjectImpl
//  extends SingleProjectCommandSupport<DockerCommands> implements DockerCommands {
//  DockerCommandsSingleProjectImpl(JefeProject project)
//    : super(
//    (JefeProject p) async => new _DockerCommandsSingleProjectImpl(project),
//    project);
//}

//class DockerCommandsMultiProjectImpl
//  extends MultiProjectCommandSupport<DockerCommands> implements DockerCommands {
//  DockerCommandsMultiProjectImpl(JefeProjectGraph graph)
//    : super(graph,
//    (JefeProject p) async => new DockerCommandsSingleProjectImpl(p));
//}

class DockerCommandsMultiProjectImpl implements DockerCommands {
  final JefeProjectGraph _graph;

  final Directory _rootDirectory;

  DockerCommandsMultiProjectImpl(this._graph, this._rootDirectory);

  @override
  Future generateDockerfile(String serverProjectName, String clientProjectName,
      {Directory outputDirectory,
      String dartVersion: 'latest',
      Map<String, dynamic> environment: const {},
      Iterable<int> exposePorts: const [],
      Iterable<String> entryPointOptions: const [],
      bool omitClientWhenPathDependencies: true,
      bool setupForPrivateGit: true,
      String targetRootPath: '/app'}) async {
    /*
      TODO: this is not getting wrapped!!!! should we call executeTask or
      should we add a different kinda base class for this case??
     */

    final serverProject = _getProjectByName('server', serverProjectName);
    final clientProject = _getProjectByName('client', clientProjectName);

    final dockerfile = new Dockerfile();

    dockerfile.from('google/dart', tag: dartVersion);

    _setupForPrivateGit(setupForPrivateGit, dockerfile);

    final serverFiles = new _TopLevelProjectFiles(
        dockerfile, serverProject, _rootDirectory.path, targetRootPath);

    final clientFiles = new _TopLevelProjectFiles(
        dockerfile, clientProject, _rootDirectory.path, targetRootPath);

    final omitClient =
        omitClientWhenPathDependencies && clientFiles.hasPathDependencies;

    final excludedDependencies = serverFiles.addAll();
    if (!omitClient) {
      clientFiles.addAll(excludeDependencies: excludedDependencies);
      dockerfile.run('pub', args: ['build']);
    }

    final pathHandler = new _PathHandler(
        _rootDirectory.path,
        targetRootPath,
        serverFiles.hasPathDependencies &&
            (omitClient || clientFiles.hasPathDependencies));

    dockerfile.envs(environment);

    dockerfile.expose(exposePorts);

    dockerfile.cmd([]);

    final serverMain =
        p.join(serverProject.installDirectory.path, 'bin/server.dart');

    dockerfile.workDir(serverFiles.workDir);

    dockerfile.entryPoint('/usr/bin/dart',
        args: concat(<Iterable<String>>[
          entryPointOptions,
          [pathHandler.targetPath(serverMain)]
        ]));

    final saveDirectory =
        outputDirectory != null ? outputDirectory : _rootDirectory;
    await dockerfile.save(saveDirectory);
  }

//      return executeTask('generate Dockerfile', () => foo()
//);

  Future generateProductionDockerfile(
      String serverProjectName, String clientProjectName,
      {String serverGitRef,
      String clientGitRef,
      Directory outputDirectory,
      String dartVersion: 'latest',
      Map<String, dynamic> environment: const {},
      Iterable<int> exposePorts: const [],
      Iterable<String> entryPointOptions: const [],
      String targetRootPath: '/app'}) async {
    final serverProject = _getProjectByName('server', serverProjectName);
    final clientProject = _getProjectByName('client', clientProjectName);

    final pathHandler =
        new _PathHandler(_rootDirectory.path, targetRootPath, false);

    final dockerfile = new Dockerfile();

    dockerfile.from('google/dart', tag: dartVersion);

    _setupForPrivateGit(true, dockerfile);

    await _cloneTopLevelProject(
        dockerfile, serverProject, serverGitRef, pathHandler);
    await _cloneTopLevelProject(
        dockerfile, clientProject, clientGitRef, pathHandler);
    dockerfile.run('pub', args: ['build']);

    dockerfile.envs(environment);

    dockerfile.expose(exposePorts);

    dockerfile.cmd([]);

    dockerfile
        .workDir(pathHandler.targetPath(serverProject.installDirectory.path));

    final serverMain =
        p.join(serverProject.installDirectory.path, 'bin/server.dart');

    dockerfile.entryPoint('/usr/bin/dart',
        args: concat(<Iterable<String>>[
          entryPointOptions,
          [pathHandler.targetPath(serverMain)]
        ]));

    final saveDirectory =
        outputDirectory != null ? outputDirectory : _rootDirectory;
    await dockerfile.save(saveDirectory);
  }

  Future _cloneTopLevelProject(
      Dockerfile dockerfile,
      JefeProject topLevelProject,
      String gitRef,
      _PathHandler pathHandler) async {
    final ref = gitRef != null
        ? gitRef
        : (await gitCurrentTagName(await topLevelProject.gitDir)).value;

    final dir = topLevelProject.installDirectory;
    final dirPath = dir.path;

    final targetPath = pathHandler.targetPath(dirPath);
    dockerfile.run('git',
        args: ['clone', '-q', '-b', ref, topLevelProject.gitUri, targetPath]);
    dockerfile.workDir(targetPath);
//    dockerfile.run('git', args: ['checkout', '-q', ref]);

    dockerfile.run('pub', args: ['get']);
  }

//  Set<Project> _pathDependentProjects(ProjectDependencies projectDependencies) {
//    final depMap = new Map.fromIterable(projectDependencies.allDependencies,
//        key: (project) => project.name);
//
//    final allProjects = concat(
//        [[projectDependencies.project], projectDependencies.allDependencies]);
//
//    final pathKeys = allProjects.expand((Project project) {
//      final deps = project.pubspec.dependencies;
//      return deps.keys.where(
//          (key) => deps[key] is PathReference && depMap.keys.contains(key));
//    });
//
//    return pathKeys.map((key) => depMap[key]).toSet();
//  }

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

  JefeProject _getProjectByName(String type, String name) =>
      (_graph.getProjectByName(name)
            ..ifAbsent(() =>
                throw new ArgumentError('$type project $name does not exist')))
          .value;
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

class _TopLevelProjectFiles {
  final Dockerfile dockerfile;
  final String rootDirectoryPath;
  final String targetRootPath;
  final String dirPath;
  final JefeProject jefeProject;

  _PathHandler get pathHandler =>
      new _PathHandler(rootDirectoryPath, targetRootPath, hasPathDependencies);

  _AddHelper get addHelper => new _AddHelper(pathHandler, dockerfile);

  _TopLevelProjectFiles(Dockerfile dockerfile, JefeProject jefeProject,
      this.rootDirectoryPath, this.targetRootPath)
      : this.dockerfile = dockerfile,
        this.jefeProject = jefeProject,
        dirPath = jefeProject.installDirectory.path;

  bool get hasPathDependencies => pathDependentProjects.isNotEmpty;

  Set<Project> get pathDependentProjects {
    final dependencyMap = new Map.fromIterable(jefeProject.allDependencies,
        key: (project) => project.name);

    final allProjects = jefeProject.allDependencies;

    final Iterable<String> pathKeys =
        allProjects.expand<String>((Project project) {
      final dependencies = project.pubspec.allDependencies;
      return dependencies.keys.where((key) =>
          dependencies[key] is PathReference &&
          dependencyMap.keys.contains(key));
    });

    return pathKeys.map<Project>((key) => dependencyMap[key]).toSet();
  }

  void addPathDependentProjects(
      {Iterable<Project> excludeDependencies: const []}) {
    pathDependentProjects
        .difference(excludeDependencies.toSet())
        .forEach((prj) {
      final dir = prj.installDirectory.path;
      dockerfile.addDir(
          pathHandler.sourcePath(dir), pathHandler.targetPath(dir));
    });
  }

  void addPubspecFiles() {
    final pubspecYaml = p.join(dirPath, 'pubspec.yaml');
    addHelper.add(pubspecYaml);

    final pubspecLock = p.join(dirPath, 'pubspec.lock');
    addHelper.add(pubspecLock);
  }

  String get workDir => pathHandler.targetPath(dirPath);

  void pubGet() {
    dockerfile.workDir(workDir);
    dockerfile.run('pub', args: ['get']);
  }

  void pubGetOffline() {
    dockerfile.workDir(workDir);
    dockerfile.run('pub', args: ['get', '--offline']);
  }

  void addWholeDirectory() {
    addHelper.addDir(dirPath);
  }

  void addRemainder() {
    addWholeDirectory();
    pubGetOffline();
  }

  Set<Project> addAll({Iterable<Project> excludeDependencies: const []}) {
    addPathDependentProjects(excludeDependencies: excludeDependencies);
    addPubspecFiles();
    pubGet();
    addWholeDirectory();
    pubGetOffline();
    return concat(
            <Iterable<Project>>[excludeDependencies, pathDependentProjects])
        .toSet();
  }
}
