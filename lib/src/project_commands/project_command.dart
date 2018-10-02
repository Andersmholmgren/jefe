// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.core;

import 'dart:async';
import 'dart:io';

import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project_commands/project_command_executor.dart';
import 'package:logging/logging.dart';

Logger _log = new Logger('jefe.project.commands.core');

/// [serialDepthFirst] means the command must execute on a single project at a time and
/// must complete execution on all the projects before the next command may be
/// executed. They will execute in depth first order of the dependencies
///
/// [concurrentProject] means that the command may execute on several projects
/// concurrently but must complete execution on all the projects before the
/// next command may be executed.
///
/// [concurrentCommand]  means that the command may execute on several projects
/// concurrently and the next command may commence on projects where this
/// command has completed before it has completed on all projects
enum CommandConcurrencyMode {
  serialDepthFirst,
  concurrentProject,
  concurrentCommand
}

/// A command that operates on a single [Project]
ProjectCommand<T> projectCommand<T>(
        String name, ProjectFunction<T> function,
        {CommandConcurrencyMode concurrencyMode:
            CommandConcurrencyMode.concurrentCommand,
        Condition condition: _alwaysYes}) =>
    new _DefaultCommand<T>(name, function, concurrencyMode, condition);

/// A command that operates on a single [Project] and the projects it depends on
ProjectCommand<T> projectCommandWithDependencies<T>(
        String name, ProjectFunction<T> function,
        {CommandConcurrencyMode concurrencyMode:
            CommandConcurrencyMode.serialDepthFirst,
        Condition condition: _alwaysYes}) =>
    new _DefaultCommand<T>(name, function, concurrencyMode, condition);

/// A command that is made up of an ordered list of other commands.
/// For a given [Project] the commands will be executed one at a time in the
/// order provided. Depending on the [concurrencyMode] of the composite command
/// and that of the individual commands, commands may be executing on other
/// [Project]s in the group simultaneously
CompositeProjectCommand<T> projectCommandGroup<T>(
    String name, Iterable<ProjectCommand<T> > commands,
    {CommandConcurrencyMode concurrencyMode:
        CommandConcurrencyMode.concurrentCommand}) {
  return new _DefaultCompositeProjectCommand<T>(
      name, commands, concurrencyMode);
}

/// A command that operates on a [JefeProjectGraph]. Unlike the other commands,
/// a ProjectDependencyGraphCommand is for tasks that require interacting with
/// several projects at once
ProjectDependencyGraphCommand<T> dependencyGraphCommand<T>(
        String name, ProjectDependencyGraphFunction<T> function) =>
    new _DefaultProjectDependencyGraphCommand<T>(name, function);

ExecutorAwareProjectCommand<T> executorAwareCommand<T>(
        String name, ExecutorAwareProjectFunction<T> function) =>
    new _DefaultExecutorAwareProjectCommand<T>(name, function);

///// Some function applied to a [Project]
//typedef Future<T> ProjectFunction<T>(Project project);
//
///// Some function applied to a [Project] with the given dependencies
//typedef Future<T> ProjectWithDependenciesFunction<T>(
//    Project project, Iterable<Project> dependencies);

typedef Future<T> ExecutorAwareProjectFunction<T>(CommandExecutor executor);

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

  Future<T> process(JefeProject project);
  Future<T> call(JefeProject project) => process(project);

  ProjectCommand<T> copy(
      {String name,
      CommandConcurrencyMode concurrencyMode,
      Condition condition});
}

/// a function that operates on the dependency graph as a whole
typedef Future<T> ProjectDependencyGraphFunction<T>(
    JefeProjectGraph graph, Directory rootDirectory, ProjectFilter filter);

/// a command that operates on the dependency graph as a whole
abstract class ProjectDependencyGraphCommand<T> extends Command {
  String get name;

  Future<T> process(
      JefeProjectGraph graph, Directory rootDirectory, ProjectFilter filter);
}

/// [concurrencyMode] can be used to limit the concurrencyMode of the
/// individual commands. Each command will execute in the more conservative of
/// the CompositeProjectCommand's value and the ProjectCommand's value.
/// TODO: this is not currently a composite. Either make it one or rename to
/// ProjectCommandGroup or something
abstract class CompositeProjectCommand<T> extends Command {
  String get name;
  Iterable<ProjectCommand<T>> get commands;
  CommandConcurrencyMode get concurrencyMode;
}

/// a [Command] that controls the execution of other commands.
abstract class ExecutorAwareProjectCommand<T> extends Command {
  // Or maybe command.process can return more commands to execute.
  // A composite would be very useful here or at least a common base class
  String get name;
  CommandConcurrencyMode get concurrencyMode;
  Future<T> process(CommandExecutor executor, {ProjectFilter filter});
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

Future<T> executeTask<T>(
    String taskDescription, Callable<T> callable) async {
  _log.info('Executing command "$taskDescription"');
  final stopWatch = new Stopwatch();
  stopWatch.start();

  try {
    final result = await callable();
    _log.info('Completed command "$taskDescription" in ${stopWatch.elapsed}');
    return result;
  } catch (e, s) {
    _log.warning('Failed command "$taskDescription" in ${stopWatch.elapsed}. '
        'Exception thrown: $e', e, s);
    rethrow;
  } finally {
    stopWatch.stop();
  }
}

class _DefaultCommand<T> extends ProjectCommand<T> {
  final String name;
  final ProjectFunction<T> function;
  final CommandConcurrencyMode concurrencyMode;
  final Condition condition;

  _DefaultCommand(
      this.name, this.function, this.concurrencyMode, this.condition);

  @override
  Future<T> process(JefeProject project) async {
    final taskDescription = '$name for project ${project.name}';
    if (!condition()) {
      _log.info(
          'Skipping command "$taskDescription" as condition does not pass');
      return null;
    }

    final Callable<T> callable = () => function(project);

    try {
      return executeTask(taskDescription, callable);
    } catch (e) {
//      print(stackTrace);
      throw new ProjectCommandError(this, project, e);
    }
  }

  String toString() => "'$name'";

  @override
  ProjectCommand<T> copy(
      {String name,
      CommandConcurrencyMode concurrencyMode,
      ProjectFunction<T> function,
      Condition condition}) {
    return new _DefaultCommand<T>(name ?? this.name, function ?? this.function,
        concurrencyMode ?? this.concurrencyMode, condition ?? this.condition);
  }
}

class _DefaultCompositeProjectCommand<T> implements CompositeProjectCommand<T> {
  final String name;
  final Iterable<ProjectCommand<T>> commands;
  final CommandConcurrencyMode concurrencyMode;
  _DefaultCompositeProjectCommand(
      this.name, this.commands, this.concurrencyMode);
}

class _DefaultProjectDependencyGraphCommand<T>
    implements ProjectDependencyGraphCommand<T> {
  final String name;
  final ProjectDependencyGraphFunction<T> function;

  _DefaultProjectDependencyGraphCommand(this.name, this.function);

  @override
  Future<T> process(JefeProjectGraph graph, Directory rootDirectory,
      ProjectFilter filter) async {
    final Callable<T> callable = () => function(graph, rootDirectory, filter);

    return executeTask(name, callable);
  }
}

class _DefaultExecutorAwareProjectCommand<T>
    implements ExecutorAwareProjectCommand<T> {
  final String name;
  final ExecutorAwareProjectFunction<T> function;
  // TODO: implement concurrencyMode
  @override
  CommandConcurrencyMode get concurrencyMode => null;

  _DefaultExecutorAwareProjectCommand(this.name, this.function);

  @override
  Future<T> process(CommandExecutor executor, {ProjectFilter filter}) async {
    final Callable<T> callable = () => function(executor);

    return executeTask(name, callable);
  }
}
