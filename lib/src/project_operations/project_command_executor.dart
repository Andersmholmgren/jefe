library devops.project.operations.executor;

import 'package:devops/src/project.dart';

import 'dart:async';
import 'package:devops/src/project_operations/project_command.dart';

import 'impl/project_command_executor.dart';

abstract class CommandExecutor {
  factory CommandExecutor(ProjectSource projectSource) = CommandExecutorImpl;

  Future execute(ProjectCommand command);

  /// executes all the commands in [composite]. If [concurrently] is true
  /// (the default) then commands will be executed on all the projects
  /// concurrently. Note: each command in the composite must complete for each
  /// project before moving on to the next command.
  /// if [concurrently] is false then each command must complete for each project
  /// before moving onto the next project.
  Future executeAll(CompositeProjectCommand composite);
}
