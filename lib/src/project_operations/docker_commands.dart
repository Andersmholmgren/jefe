library devops.project.operations.docker;

import 'package:devops/src/project_operations/project_command.dart';
import 'dart:io';
import 'impl/docker_commands_impl.dart';

abstract class DockerCommands {
  factory DockerCommands() = DockerCommandsImpl;

  /// Generates a Dockerfile based on the provided [topLevelProjectNames].
  /// If these projects have path dependencies on other projects
  /// managed by jefe then those dependent projects are added first
  ProjectDependencyGraphCommand generateDockerfile(
      Iterable<String> topLevelProjectNames, Directory outputDirectory);
}
