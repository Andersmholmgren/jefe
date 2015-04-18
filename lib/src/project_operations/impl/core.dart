import 'package:devops/src/project.dart';

import 'package:logging/logging.dart';
import 'dart:async';

Logger _log = new Logger('devops.project.operations.impl');

typedef ProjectProcessor(Project project);

typedef ProjectDependencyProcessor(
    Project project, Iterable<Project> dependencies);

abstract class BaseCommand {
  final ProjectSource _projectSource;

  BaseCommand(this._projectSource);

  Future visitAllProjects(
      String description, ProjectProcessor processor) async {
    await _projectSource
        .visitAllProjects(_wrapProcessor(description, processor));
  }

  Future depthFirst(
      String description, ProjectDependencyProcessor processor) async {
    await _projectSource.processDependenciesDepthFirst(
        _wrapDependencyProcessor(description, processor));
  }

  ProjectProcessor _wrapProcessor(
          String description, ProjectProcessor processor) =>
      (Project project) async {
    final taskDescription = '$description for project ${project.name}';
    _log.info('Starting $taskDescription');
    await processor(project);
    _log.finer('Finished $taskDescription');
  };

  ProjectDependencyProcessor _wrapDependencyProcessor(
          String description, ProjectDependencyProcessor processor) =>
      (Project project, Iterable<Project> dependencies) async {
    final taskDescription =
        '$description for project ${project.name} with ${dependencies.length} dependencies';
    _log.info('Starting $taskDescription');
    await processor(project, dependencies);
    _log.finer('Finished $taskDescription');
  };
}
