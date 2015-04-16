library devops.project.operations.executor;

import 'package:devops/src/project.dart';

import 'dart:async';
import 'package:devops/src/project_operations/project_command.dart';

import 'impl/project_command_executor.dart';

abstract class CommandExecutor {
  factory CommandExecutor(ProjectSource projectSource) =>
      new CommandExecutorImpl(projectSource);

  Future execute(ProjectCommand command);
}
