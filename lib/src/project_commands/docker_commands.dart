// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.docker;

import 'package:jefe/src/project_commands/project_command.dart';
import 'dart:io';
import 'impl/docker_commands_impl.dart';

abstract class DockerCommands {
  factory DockerCommands() = DockerCommandsImpl;

  /// Generates a Dockerfile based on the provided [serverProjectName]
  /// and [clientProjectName].
  /// If these projects have path dependencies on other projects
  /// managed by jefe then those dependent projects are added first
  ProjectDependencyGraphCommand generateDockerfile(
      String serverProjectName, String clientProjectName,
      {Directory outputDirectory, String dartVersion: 'latest',
      Map<String, dynamic> environment: const {},
      Iterable<int> exposePorts: const [],
      Iterable<String> entryPointOptions: const [],
      bool omitClientWhenPathDependencies: true, bool setupForPrivateGit: true,
      String targetRootPath: '/app'});

  /// Generates a Dockerfile based on the provided [serverProjectName]
  /// and [clientProjectName] suitable for production.
  /// The client and server projects will be cloned within the docker file
  /// base on a git tag
  ProjectDependencyGraphCommand generateProductionDockerfile(
      String serverProjectName, String clientProjectName, {String serverGitRef,
      String clientGitRef, Directory outputDirectory,
      String dartVersion: 'latest', Map<String, dynamic> environment: const {},
      Iterable<int> exposePorts: const [],
      Iterable<String> entryPointOptions: const [],
      String targetRootPath: '/app'});
}
