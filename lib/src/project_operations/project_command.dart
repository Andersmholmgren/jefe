library devops.project.operations.core;

import 'package:devops/src/project.dart';
import 'dart:async';

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

ProjectCommand projectCommand(String name, ProjectFunction function,
        {CommandConcurrencyMode concurrencyMode: CommandConcurrencyMode.concurrentCommand}) =>
    new _DefaultCommand(name, function, concurrencyMode);

ProjectCommand projectCommandWithDependencies(
        String name, ProjectWithDependenciesFunction function,
        {CommandConcurrencyMode concurrencyMode: CommandConcurrencyMode.serial}) =>
    new _DefaultCommand(name, function, concurrencyMode);

CompositeProjectCommand projectCommandGroup(
    String name, Iterable<ProjectCommand> commands,
    {CommandConcurrencyMode concurrencyMode: CommandConcurrencyMode.concurrentCommand}) {
}

/// Some function applied to a [Project]
typedef ProjectFunction(Project project);

/// Some function applied to a [Project] with the given dependencies
typedef ProjectWithDependenciesFunction(
    Project project, Iterable<Project> dependencies);

abstract class ProjectCommand<F extends Function> {
  String get name;
  F get function;
  CommandConcurrencyMode get concurrencyMode;
}

abstract class ProjectCommand2 {
  String get name;
  CommandConcurrencyMode get concurrencyMode;
  Future process(Project project, Iterable<Project> dependencies);
}

/// [concurrencyMode] can be used to limit the concurrencyMode of the
/// individual commands. Each command will execute in the more conservative of
/// the CompositeProjectCommand's value and the ProjectCommand's value.
abstract class CompositeProjectCommand {
  String get name;
  Iterable<ProjectCommand> get commands;
  CommandConcurrencyMode get concurrencyMode;
}

//abstract class ProjectCommand extends Command<ProjectFunction> {}
//
//abstract class ProjectWithDependenciesFunctionCommand
//    extends Command<ProjectWithDependenciesFunction> {}

class _DefaultCommand<F extends Function> implements ProjectCommand<F> {
  final String name;
  final F function;
  final CommandConcurrencyMode concurrencyMode;

  _DefaultCommand(this.name, this.function, this.concurrencyMode);
}

//class _DefaultCommand2 implements ProjectCommand2 {
//  final String name;
//  final Function function;
//  final CommandConcurrencyMode concurrencyMode;
//
//  _DefaultCommand2(this.name, this.function, this.concurrencyMode);
//
//  @override
//  Future process(Project project, Iterable<Project> dependencies) {
//    return function is ProjectWithDependenciesFunction ? function(project,
//    dependencies) : function(project);
//  }
//}

class _DefaultCompositeProjectCommand implements CompositeProjectCommand {}

//class _DefaultCompositeProjectCommand2 implements ProjectCommand2 {
//  final String name;
//  final F function;
//  final CommandConcurrencyMode concurrencyMode;
//
//}

//class _CompositeCommand implements ProjectCommand<ProjectFunction> {
//  final String name;
//  final Iterable<ProjectCommand> commands;
//
//  _CompositeCommand(this.name, this.commands);
//
//  @override
//  ProjectFunction get function => (Project project) {
//    Future.forEach(commands, (ProjectCommand command) {
//      await command
//    });
//  };
//}

//class _CompositeCommand<F extends Function> implements ProjectCommand<F> {
//  final String name;
//  final Iterable<ProjectCommand> commands;
//
//  _CompositeCommand(this.name, this.commands);
//
//  @override
//  F get function => null;
//}
