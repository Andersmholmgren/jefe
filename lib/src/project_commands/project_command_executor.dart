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

  /// Executes the [Command] on all the [Project]s in the group that match
  /// the [filter].
  Future execute(Command command,
      {CommandConcurrencyMode concurrencyMode, ProjectFilter filter});
}
