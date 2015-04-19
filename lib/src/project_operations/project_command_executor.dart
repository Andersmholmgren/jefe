library devops.project.operations.executor;

import 'dart:async';
import 'package:devops/src/project_operations/project_command.dart';

import 'impl/project_command_executor.dart';
import 'package:devops/src/project/core.dart';

abstract class CommandExecutor {
  factory CommandExecutor(ProjectSource projectSource) = CommandExecutorImpl;

  // TODO: should allow concurrencyMode here
  Future execute(ProjectCommand command);

  /// executes all the commands in [composite]. Optionally a [concurrencyMode]
  /// can be provided to run the commands in a more conservative concurrency
  /// mode than may be supported by the underlying commands
  Future executeAll(CompositeProjectCommand composite,
      {CommandConcurrencyMode concurrencyMode: CommandConcurrencyMode.concurrentCommand});

  Future executeOn(ProjectCommand command, String projectName);

  Future executeOnGraph(ProjectDependencyGraphCommand command);
}
