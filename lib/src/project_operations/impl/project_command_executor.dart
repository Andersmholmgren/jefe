library devops.project.operations.executor.impl;

import 'package:devops/src/project.dart';

import 'package:logging/logging.dart';
import 'dart:async';
import 'package:devops/src/project_operations/project_command.dart';
import 'package:devops/src/project_operations/project_command_executor.dart';
import 'dart:collection';
import 'package:option/option.dart';
import 'package:frappe/frappe.dart';
import 'package:devops/src/util/frappe_utils.dart';

Logger _log = new Logger('devops.project.operations.impl');

class CommandExecutorImpl implements CommandExecutor {
  final ProjectSource _projectSource;

  CommandExecutorImpl(this._projectSource);

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
    _log.info('Executing command "$taskDescription"');
    await processor(project);
    _log.finer('Completed command "$taskDescription"');
  };

  ProjectWithDependenciesFunction _wrapDependencyProcessor(
          String description, ProjectWithDependenciesFunction processor) =>
      (Project project, Iterable<Project> dependencies) async {
    final taskDescription =
        '$description for project ${project.name} with ${dependencies.length} dependencies';
    _log.info('Executing command "$taskDescription"');
    await processor(project, dependencies);
    _log.finer('Completed command "$taskDescription"');
  };

//  Future executeAll(Iterable<ProjectCommand> commands) =>
//      Future.forEach(commands, execute);
//  // TODO: this is the safest approach. It will execute each command from scratch
//  // reevaluating allProjects and reloading all projects for each command
//  // More efficient thought is if projects loaded once and then each command run
//  // on them in turn

  @override
  Future executeAll(CompositeProjectCommand composite,
      {bool concurrently: true}) async {
    if (concurrently) {
      await _executeConcurrently(composite);
    } else {
      await _executeSerially(composite);
    }
  }

  /////// BAD IDEA. Can't do this
  Future _executeConcurrently(CompositeProjectCommand composite) async {
    final wrappedCommand = projectCommandWithDependencies(composite.name,
        (Project project, Iterable<Project> dependencies) async {
      await Future.forEach(composite.commands, (ProjectCommand command) async {
        if (command.function is ProjectWithDependenciesFunction) {
          await command.function(project, dependencies);
        } else if (command.function is ProjectFunction) {
          await command.function(project);
        } else {
          throw new ArgumentError('Invalid function passed into execute');
        }
      });
    });

    await execute(wrappedCommand);
  }

  Future _executeSerially(CompositeProjectCommand composite) async {
    _log.info('Executing composite command "${composite.name}"');
    await Future.forEach(composite.commands, execute);
    _log.finer('Completed command "${composite.name}"');
  }
}

typedef Future CommandExecutorFunction(ProjectCommand command);

class ProjectCommandQueue {
  final Queue<ProjectCommand> _queue = new Queue();
  Option<ProjectCommand> _pending = const None();
  final CommandExecutorFunction _executor;
  final ControllableProperty<bool> _queueIsEmpty =
      new ControllableProperty(true);
  Property<bool> get queueIsEmpty => _queueIsEmpty.distinctProperty;

  ProjectCommandQueue(this._executor);

  void add(ProjectCommand command) {
    _queue.add(command);
    _queueIsEmpty.value = false;
    _check();
  }

  Future _check() async {
    if (_pending is None && _queue.isNotEmpty) {
      final command = _queue.removeFirst();
      _pending = new Some(command);
      // TODO: should we attempt to catch exceptions?
      await _executor(command);
      _check();
    } else if (_pending is None && _queue.isEmpty) {
      _queueIsEmpty.value = true;
    }
  }
}
