import 'package:devops/src/project.dart';

import 'package:logging/logging.dart';
import 'dart:async';
import 'package:devops/src/project_operations/project_command.dart';

Logger _log = new Logger('devops.project.operations.impl');

class BaseCommandExecutor {
  final ProjectSource _projectSource;

  BaseCommandExecutor(this._projectSource);

  Future execute(ProjectCommand command) async {
    if (command.function is ProjectWithDependenciesFunction) {
      await _depthFirst(command.name, command.function);
    } else if (command.function is ProjectFunction) {
      await _visitAllProjects(command.name, command.function);
    } else {
      throw new ArgumentError('Invalid function passed into execute');
    }
  }

  Future _visitAllProjects(
      String description, ProjectFunction processor) async {
    await _projectSource
        .visitAllProjects(_wrapProcessor(description, processor));
  }

  Future _depthFirst(
      String description, ProjectWithDependenciesFunction processor) async {
    await _projectSource.processDependenciesDepthFirst(
        _wrapDependencyProcessor(description, processor));
  }

  ProjectFunction _wrapProcessor(
          String description, ProjectFunction processor) =>
      (Project project) async {
    final taskDescription = '$description for project ${project.name}';
    _log.info('Starting $taskDescription');
    await processor(project);
    _log.finer('Finished $taskDescription');
  };

  ProjectWithDependenciesFunction _wrapDependencyProcessor(
          String description, ProjectWithDependenciesFunction processor) =>
      (Project project, Iterable<Project> dependencies) async {
    final taskDescription =
        '$description for project ${project.name} with ${dependencies.length} dependencies';
    _log.info('Starting $taskDescription');
    await processor(project, dependencies);
    _log.finer('Finished $taskDescription');
  };
}
