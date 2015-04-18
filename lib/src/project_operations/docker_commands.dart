library devops.project.operations.docker;

import 'package:devops/src/project_operations/project_command.dart';
import 'dart:io';

abstract class DockerCommands {
//  factory DockerCommands() = DockerCommandsImpl;

  /// Invokes the provided command with the projects directory as the processes
  /// working directory
  ProjectDependencyGraphCommand generateDockerfile(
      Iterable<String> topLevelProjectNames, Directory outputDirectory);
}
