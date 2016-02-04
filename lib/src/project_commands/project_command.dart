// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.core;

import 'package:jefe/src/project/project.dart';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:jefe/src/project/dependency_graph.dart';
import 'dart:io';
import 'package:jefe/src/project_commands/project_command_executor.dart';

Logger _log = new Logger('jefe.project.commands.core');

/// [serial] means the command must execute on a single project at a time and
/// must complete execution on all the projects before the next command may be
/// executed.
///
/// [concurrentProject] means that the command may execute on several projects
/// concurrently but must complete execution on all the projects before the
/// next command may be executed.
///
/// [concurrentCommand]  means that the command may execute on several projects
/// concurrently and the next command may commence on projects where this
/// command has completed before it has completed on all projects
enum CommandConcurrencyMode { serial, concurrentProject, concurrentCommand }

/// A command that operates on a single [Project]
ProjectCommand projectCommand(String name, ProjectFunction function,
        {CommandConcurrencyMode concurrencyMode:
            CommandConcurrencyMode.concurrentCommand,
        Condition condition: _alwaysYes}) =>
    new _DefaultCommand(name, function, concurrencyMode, condition);

/// A command that operates on a single [Project] and the projects it depends on
ProjectCommand projectCommandWithDependencies(
        String name, ProjectWithDependenciesFunction function,
        {CommandConcurrencyMode concurrencyMode: CommandConcurrencyMode.serial,
        Condition condition: _alwaysYes}) =>
    new _DefaultCommand(name, function, concurrencyMode, condition);

/// A command that is made up of an ordered list of other commands.
/// For a given [Project] the commands will be executed one at a time in the
/// order provided. Depending on the [concurrencyMode] of the composite command
/// and that of the individual commands, commands may be executing on other
/// [Project]s in the group simultaneously
CompositeProjectCommand projectCommandGroup(
    String name, Iterable<ProjectCommand> commands,
    {CommandConcurrencyMode concurrencyMode:
        CommandConcurrencyMode.concurrentCommand}) {
  return new _DefaultCompositeProjectCommand(name, commands, concurrencyMode);
}

/// A command that operates on a [DependencyGraph]. Unlike the other commands,
/// a ProjectDependencyGraphCommand is for tasks that require interacting with
/// several projects at once
ProjectDependencyGraphCommand dependencyGraphCommand(
        String name, ProjectDependencyGraphFunction function) =>
    new _DefaultProjectDependencyGraphCommand(name, function);

ExecutorAwareProjectCommand executorAwareCommand(
        String name, ExecutorAwareProjectFunction function) =>
    new _DefaultExecutorAwareProjectCommand(name, function);

/// Some function applied to a [Project]
typedef ProjectFunction(Project project);

/// Some function applied to a [Project] with the given dependencies
typedef ProjectWithDependenciesFunction(
    Project project, Iterable<Project> dependencies);

typedef ExecutorAwareProjectFunction(CommandExecutor executor);

typedef bool Condition();

bool _alwaysYes() => true;

abstract class Command {
  String get name;

//  CommandConcurrencyMode get concurrencyMode;

//  Condition get condition;
}

/// A command that can be executed on a [Project] and optionally it's set of
/// [dependencies]
abstract class ProjectCommand<T> extends Command {
  String get name;
  CommandConcurrencyMode get concurrencyMode;
  Condition get condition;

  Future<T> process(Project project, {Iterable<Project> dependencies});

  ProjectCommand copy(
      {String name,
      CommandConcurrencyMode concurrencyMode,
      Condition condition});
}

/// a function that operates on the dependency graph as a whole
typedef Future ProjectDependencyGraphFunction(
    DependencyGraph graph, Directory rootDirectory, ProjectFilter filter);

/// a command that operates on the dependency graph as a whole
abstract class ProjectDependencyGraphCommand extends Command {
  String get name;
  Future process(
      DependencyGraph graph, Directory rootDirectory, ProjectFilter filter);
}

/// [concurrencyMode] can be used to limit the concurrencyMode of the
/// individual commands. Each command will execute in the more conservative of
/// the CompositeProjectCommand's value and the ProjectCommand's value.
/// TODO: this is not currently a composite. Either make it one or rename to
/// ProjectCommandGroup or something
abstract class CompositeProjectCommand extends Command {
  String get name;
  Iterable<ProjectCommand> get commands;
  CommandConcurrencyMode get concurrencyMode;
}

/// a [Command] that controls the execution of other commands.
abstract class ExecutorAwareProjectCommand extends Command {
  // Or maybe command.process can return more commands to execute.
  // A composite would be very useful here or at least a common base class
  String get name;
  CommandConcurrencyMode get concurrencyMode;
  Future process(CommandExecutor executor, {ProjectFilter filter});
}

class ProjectCommandError {
  final ProjectCommand command;
  final Project project;
  final cause;

  String get message => 'Error executing $command on $project. Cause: $cause';

  ProjectCommandError(this.command, this.project, this.cause);

  String toString() => 'ProjectCommandError: $message';
}

typedef Future<T> Callable<T>();

Future /*<T>*/ executeCallable /*<T>*/ (
    Callable /*<T>*/ callable, String taskDescription) async {
  _log.info('Executing command "$taskDescription"');
  final stopWatch = new Stopwatch();
  stopWatch.start();

  try {
    final result = await callable();
    _log.info('Completed command "$taskDescription" in ${stopWatch.elapsed}');
    return result;
  } catch (e) {
    _log.warning('Failed command "$taskDescription" in ${stopWatch.elapsed}. '
        'Exception thrown: $e');
    rethrow;
  } finally {
    stopWatch.stop();
  }
}

class _DefaultCommand implements ProjectCommand {
  final String name;
  final Function function;
  final CommandConcurrencyMode concurrencyMode;
  final Condition condition;

  _DefaultCommand(
      this.name, this.function, this.concurrencyMode, this.condition);

  @override
  Future process(Project project,
      {Iterable<Project> dependencies: const []}) async {
    final taskDescription = '$name for project ${project.name}';
    if (!condition()) {
      _log.info(
          'Skipping command "$taskDescription" as condition does not pass');
      return null;
    }

    if (function is! ProjectWithDependenciesFunction &&
        function is! ProjectFunction) {
      throw new ArgumentError('Invalid function passed into process');
    }

    final Callable callable = () => (function is ProjectWithDependenciesFunction
        ? function(project, dependencies)
        : function(project));

    try {
      return executeCallable(callable, taskDescription);
    } catch (e) {
//      print(stackTrace);
      throw new ProjectCommandError(this, project, e);
    }
  }

  String toString() => "'$name'";

  @override
  ProjectCommand copy(
      {String name,
      CommandConcurrencyMode concurrencyMode,
      Function function,
      Condition condition}) {
    return new _DefaultCommand(
        name != null ? name : this.name,
        function != null ? function : this.function,
        concurrencyMode != null ? concurrencyMode : this.concurrencyMode,
        condition != null ? condition : this.condition);
  }
}

class _DefaultCompositeProjectCommand implements CompositeProjectCommand {
  final String name;
  final Iterable<ProjectCommand> commands;
  final CommandConcurrencyMode concurrencyMode;
  _DefaultCompositeProjectCommand(
      this.name, this.commands, this.concurrencyMode);
}

class _DefaultProjectDependencyGraphCommand
    implements ProjectDependencyGraphCommand {
  final String name;
  final ProjectDependencyGraphFunction function;

  _DefaultProjectDependencyGraphCommand(this.name, this.function);

  @override
  Future process(DependencyGraph graph, Directory rootDirectory,
      ProjectFilter filter) async {
    _log.info('Executing command "$name"');
    final stopWatch = new Stopwatch();
    stopWatch.start();

    final result = await function(graph, rootDirectory, filter);

    _log.finer('Completed command "$name" in ${stopWatch.elapsed}');
    stopWatch.stop();
    return result;
  }
}

class _DefaultExecutorAwareProjectCommand
    implements ExecutorAwareProjectCommand {
  final String name;
  final ExecutorAwareProjectFunction function;
  // TODO: implement concurrencyMode
  @override
  CommandConcurrencyMode get concurrencyMode => null;

  _DefaultExecutorAwareProjectCommand(this.name, this.function);

  @override
  Future process(CommandExecutor executor, {ProjectFilter filter}) async {
    _log.info('Executing command "$name"');
    final stopWatch = new Stopwatch();
    stopWatch.start();

    final result = await function(executor);

    _log.finer('Completed command "$name" in ${stopWatch.elapsed}');
    stopWatch.stop();
    return result;
  }
}
