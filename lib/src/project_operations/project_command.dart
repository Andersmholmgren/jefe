library devops.project.operations.core;

import 'package:devops/src/project.dart';

ProjectCommand projectCommand(String name, ProjectFunction function) =>
    new _DefaultCommand(name, function);

ProjectCommand projectCommandWithDependencies(
        String name, ProjectWithDependenciesFunction function) =>
    new _DefaultCommand(name, function);

/// Some function applied to a [Project]
typedef ProjectFunction(Project project);

/// Some function applied to a [Project] with the given dependencies
typedef ProjectWithDependenciesFunction(
    Project project, Iterable<Project> dependencies);

abstract class ProjectCommand<F extends Function> {
  String get name;
  F get function;
}

//abstract class ProjectCommand extends Command<ProjectFunction> {}
//
//abstract class ProjectWithDependenciesFunctionCommand
//    extends Command<ProjectWithDependenciesFunction> {}

class _DefaultCommand<F extends Function> implements ProjectCommand<F> {
  final String name;
  final F function;

  _DefaultCommand(this.name, this.function);
}
