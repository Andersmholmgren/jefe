// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.executor;

import 'dart:async';
import 'package:jefe/src/project_commands/project_command.dart';

import 'impl/project_command_executor.dart';
import 'dart:io';
import 'package:jefe/src/project/project_group.dart';
import 'package:jefe/src/project/project.dart';

Future<CommandExecutor> executorForDirectory(String rootDirectory) async =>
    new CommandExecutor(await ProjectGroup.load(new Directory(rootDirectory)));

typedef bool ProjectFilter(Project p);

ProjectFilter projectNameFilter(String pattern) =>
    (Project p) => pattern == null || p.name.contains(pattern);

/// Facilitates the execution of commands on a [ProjectGroup]
abstract class CommandExecutor {
  factory CommandExecutor(ProjectGroup projectGroup) = CommandExecutorImpl;

  /// Excutes a single [ProjectCommand] on all the [Project]s in the group
  // TODO: should allow concurrencyMode here
  Future execute(ProjectCommand command,
      {CommandConcurrencyMode concurrencyMode: CommandConcurrencyMode.concurrentProject,
      ProjectFilter filter});

  /// executes all the commands in [composite]. Optionally a [concurrencyMode]
  /// can be provided to run the commands in a more conservative concurrency
  /// mode than may be supported by the underlying commands
  Future executeAll(CompositeProjectCommand composite,
      {CommandConcurrencyMode concurrencyMode: CommandConcurrencyMode.concurrentCommand,
      ProjectFilter filter});

  /// Executes the [ProjectCommand] on a single poject with the name [projectName]
  /// TODO: maybe projectName should be a pattern instead
  Future executeOn(ProjectCommand command, String projectName);

  /// Executes the [ProjectDependencyGraphCommand] on the [DependencyGraph]
  /// of the project group
  Future executeOnGraph(ProjectDependencyGraphCommand command,
      {ProjectFilter filter});
}
