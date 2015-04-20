// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.executor;

import 'dart:async';
import 'package:jefe/src/project_commands/project_command.dart';

import 'impl/project_command_executor.dart';
import 'dart:io';
import 'package:jefe/src/project/project_group.dart';

Future<CommandExecutor> executorForDirectory(String rootDirectory) async =>
    new CommandExecutor(await ProjectGroup.load(new Directory(rootDirectory)));

abstract class CommandExecutor {
  factory CommandExecutor(ProjectGroup projectGroup) = CommandExecutorImpl;

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
