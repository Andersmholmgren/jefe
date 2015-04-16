library devops.project.operations.core;

import 'package:devops/src/project.dart';

Command projectCommand(String name, ProjectFunction function) =>
    new _DefaultCommand(name, function);

Command projectCommandWithDependencies(
        String name, ProjectWithDependenciesFunction function) =>
    new _DefaultCommand(name, function);

typedef ProjectFunction(Project project);

typedef ProjectWithDependenciesFunction(
    Project project, Iterable<Project> dependencies);

abstract class Command<F extends Function> {
  String get name;
  F get function;
}

abstract class ProjectCommand extends Command<ProjectFunction> {}

abstract class ProjectWithDependenciesFunctionCommand
    extends Command<ProjectWithDependenciesFunction> {}

class _DefaultCommand implements Command {
  final String name;
  final Function function;

  _DefaultCommand(this.name, this.function);
}
