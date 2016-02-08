// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.executor.impl;

import 'dart:async';

import 'package:jefe/src/project/dependency_graph.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project/project_group.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:jefe/src/project_commands/project_command_executor.dart';
import 'package:logging/logging.dart';
import 'package:option/option.dart';

Logger _log = new Logger('jefe.project.commands.impl');

class CommandExecutorImpl implements CommandExecutor {
  final ProjectGroup _projectGroup;

  CommandExecutorImpl(this._projectGroup);

  @override
  Future execute(Command command,
      {CommandConcurrencyMode concurrencyMode:
          CommandConcurrencyMode.concurrentProject,
      ProjectFilter filter: _noOpFilter}) async {
    if (command is ProjectCommand) {
      return executeOnProject(command,
          concurrencyMode: concurrencyMode, filter: filter);
    } else if (command is CompositeProjectCommand) {
      return executeAll(command,
          concurrencyMode: concurrencyMode, filter: filter);
    } else if (command is ProjectDependencyGraphCommand) {
      return executeOnGraph(command,
          /*concurrencyMode: concurrencyMode,*/
          filter: filter);
    } else if (command is ExecutorAwareProjectCommand) {
      return executeWithExecutor(command,
          /*concurrencyMode: concurrencyMode,*/
          filter: filter);
    } else {
      throw new StateError('command type not implemented');
    }
  }

  Future executeOnProject(ProjectCommand command,
      {CommandConcurrencyMode concurrencyMode:
          CommandConcurrencyMode.concurrentProject,
      ProjectFilter filter: _noOpFilter}) async {
    final _filter = filter != null ? filter : _noOpFilter;

    final executionMode = concurrencyMode.index < command.concurrencyMode.index
        ? concurrencyMode
        : command.concurrencyMode;

    if (executionMode == CommandConcurrencyMode.concurrentProject ||
        executionMode == CommandConcurrencyMode.concurrentCommand) {
      return await _executeOnConcurrentProjects(
          await _projectGroup.rootJefeProjects, command, filter);
    } else {
      return await _processDependenciesDepthFirst(
          (Project project, Iterable<Project> dependencies) async {
        if (_filter(project)) {
          return await command.process(project, dependencies: dependencies);
        }
      });
    }
  }

  Future _processDependenciesDepthFirst(
      process(Project project, Iterable<Project> dependencies)) async {
    return (await _projectGroup.rootJefeProjects).processDepthFirst(process);
  }

//  ProjectWithDependenciesFunction _wrapDependencyProcessor(
//          String description, ProjectWithDependenciesFunction processor) =>
//      (Project project, Iterable<Project> dependencies) async {
//    final taskDescription =
//        '$description for project ${project.name} with ${dependencies.length} dependencies';
//    _log.info('Executing command "$taskDescription"');
//    await processor(project, dependencies);
//    _log.finer('Completed command "$taskDescription"');
//  };

//  Future executeAll(Iterable<ProjectCommand> commands) =>
//      Future.forEach(commands, execute);
//  // TODO: this is the safest approach. It will execute each command from scratch
//  // reevaluating allProjects and reloading all projects for each command
//  // More efficient thought is if projects loaded once and then each command run
//  // on them in turn

  Future executeAll(CompositeProjectCommand composite,
      {CommandConcurrencyMode concurrencyMode:
          CommandConcurrencyMode.concurrentCommand,
      ProjectFilter filter: _noOpFilter}) async {
    final _filter = filter != null ? filter : _noOpFilter;
    if (concurrencyMode != CommandConcurrencyMode.serial &&
        composite.commands
            .every((c) => c.concurrencyMode != CommandConcurrencyMode.serial)) {
      return _executeAllOnConcurrentProjects(composite, _filter);
    } else {
      return _executeSerially(composite, _filter);
    }

    // TODO: add support for concurrentCommand
  }

  Future _executeSerially(
      CompositeProjectCommand composite, ProjectFilter filter) async {
    _log.info('Executing composite command "${composite.name} serially"');
    final result = await Future.forEach(
        composite.commands, (c) => execute(c, filter: filter));
    _log.finer('Completed composite command "${composite.name}"');
    return result;
  }

  // executes concurrently on all projects but each command must complete on all
  // projects before moving on to next
  Future _executeAllOnConcurrentProjects(
      CompositeProjectCommand composite, ProjectFilter filter) async {
    _log.info('Executing composite command "${composite.name} '
        'concurrently on all projects"');
    final projectGraph = await _projectGroup.rootJefeProjects;

    await Future.forEach(composite.commands, (command) async {
      await _executeOnConcurrentProjects(projectGraph, command, filter);
    });

    _log.finer('Completed composite command "${composite.name}"');
  }

  Future _executeOnConcurrentProjects(JefeProjectGraph projectGraph,
      ProjectCommand command, ProjectFilter filter) async {
    return await new Stream.fromIterable(
            projectGraph.depthFirst.map((JefeProject pd) async {
      if (filter(pd)) {
        return await command.process(pd, dependencies: pd.directDependencies);
      }
    }).toList())
        .asyncMap((result) => result)
        .toList();
  }

  Future executeOn(ProjectCommand command, String projectName) async {
    final JefeProjectGraph graph =
        await getRootProjects(await _projectGroup.allProjects);
    final jefeProjectOpt = graph.getProjectByName(projectName);
    if (jefeProjectOpt is None) {
      throw new ArgumentError.value(
          projectName, 'projectName', 'No such project found');
    }
    final jefeProject = jefeProjectOpt.get();

    return await command.process(jefeProject.project,
        dependencies: jefeProject.directDependencies);
  }

  Future executeOnGraph(ProjectDependencyGraphCommand command,
      {ProjectFilter filter: _noOpFilter}) async {
    final _filter = filter != null ? filter : _noOpFilter;
    final JefeProjectGraph graph =
        await getRootProjects(await _projectGroup.allProjects);
    return await command.process(
        graph, _projectGroup.containerDirectory, _filter);
  }

  Future executeWithExecutor(ExecutorAwareProjectCommand command,
          {ProjectFilter filter}) =>
      command.process(this, filter: filter);
}

typedef Future CommandExecutorFunction(ProjectCommand command);
/*
/// TODO: will need something like this.
/// - maintain queues per project
/// - commands always execute serially on a project
/// - add commands to queues according to concurrency mode
class ConcurrentCommandExecutor {
  Map<String, ProjectCommandQueue> _projectQueues;
  final CommandConcurrencyMode concurrencyMode;
  final ProjectGroup projectGroup;

  Iterable<Project> get projects => projectGroup.allProjects;
  Future<Iterable<ProjectDependencies>> get depthFirst async =>
      (await getDependencyGraph(projects)).depthFirst;

  Option<ProjectCommandQueue> getQueue(Project project) =>
      new Option(_projectQueues[project.name]);

  Future awaitQueuesEmpty() {
//    _projectQueues.values.((q) => q.queueIsEmpty)
  }

  Future execute(Iterable<ProjectCommand> commands) {
    // TODO: forEach won't work. In some cases need to wait till stuff finishes
    commands.forEach((command) async {
      final CommandConcurrencyMode mode = concurrencyMode.index <
              command.concurrencyMode.index
          ? concurrencyMode
          : command.concurrencyMode;

      switch (mode) {
        case CommandConcurrencyMode.serial:
          // depthFirst. Await completion
          final projectDeps = await depthFirst;
          await Future.forEach(projectDeps, (ProjectDependencies pd) async {
            final qOpt = getQueue(pd.project);
//            qOpt.map((q) )
            if (qOpt is Some) {
              // TODO: assuming has depends
              await qOpt.get().add(() => command.process(pd.project,
                  dependencies: pd.directDependencies));
            }
          });

          break;
        case CommandConcurrencyMode.concurrentProject:
        // add to all queues. Wait till all queues empty
        case CommandConcurrencyMode.concurrentCommand:
        // add to all queues and move to next command
        default:
          throw new StateError('unexpected concurrency mode: $mode');
      }
    });
  }
}

typedef ProjectCommandExecution();

class ProjectCommandQueue {
  final Queue<ProjectCommandExecution> _queue = new Queue();
  Option<ProjectCommandExecution> _pending = const None();
  final ControllableProperty<bool> _queueIsEmpty =
      new ControllableProperty(true);
  Property<bool> get queueIsEmpty => _queueIsEmpty.distinctProperty;

//  ProjectCommandQueue(this._executor);

  void add(ProjectCommandExecution command) {
    _queue.add(command);
    _queueIsEmpty.value = false;
    _check();
  }

  Future _check() async {
    if (_pending is None && _queue.isNotEmpty) {
      final command = _queue.removeFirst();
      _pending = new Some(command);
      // TODO: should we attempt to catch exceptions?
      await command();
      _check();
    } else if (_pending is None && _queue.isEmpty) {
      _queueIsEmpty.value = true;
    }
  }
}
*/

bool _noOpFilter(Project p) => true;
