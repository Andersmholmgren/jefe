import 'package:jefe/src/project/jefe_project.dart';
import 'dart:async';
import 'package:jefe/src/project_commands/project_command.dart'
    show Callable, CommandConcurrencyMode, executeTask;

typedef Future<S> SingleProjectCommandFactory<S>(JefeProject project);
typedef Future<T> SingleProjectCommand<S, T>(S single);
typedef Callable<T> _Processor<T>(ProjectFunction/*<T>*/ command,
    {ProjectFilter filter, Combiner/*<T>*/ combine});

abstract class BaseCommandsImpl<S> implements JefeGroupCommand<S> {
  final JefeProjectGraph graph;
  final SingleProjectCommandFactory<S> _singleProjectCommandFactory;

  BaseCommandsImpl(this.graph, this._singleProjectCommandFactory);

  Future<S> singleProjectCommandFor(JefeProject project) =>
      _singleProjectCommandFactory(project);

  Future/*<T>*/ processAllConcurrently2/*<T>*/(
      String taskDescription, SingleProjectCommand<S, dynamic/*=T*/ > command,
      {ProjectFilter filter, Combiner/*<T>*/ combine}) {
    Future/*<T>*/ _executeOnSingleProject(JefeProject p) async {
      return command(await singleProjectCommandFor(p));
    }

    return graph.processAllConcurrently(_executeOnSingleProject,
        filter: filter, combine: combine);
  }

  Future/*<T>*/ processDepthFirst/*<T>*/(ProjectFunction/*<T>*/ command,
          {ProjectFilter filter, Combiner/*<T>*/ combine}) =>
      graph.processDepthFirst(command, filter: filter, combine: combine);

  Callable/*<T>*/ _concurrentProcessor/*<T>*/(ProjectFunction/*<T>*/ command,
      {ProjectFilter filter, Combiner/*<T>*/ combine}) {
    return () =>
        graph.processAllConcurrently(command, filter: filter, combine: combine);
  }

  Callable/*<T>*/ _serialProcessor/*<T>*/(ProjectFunction/*<T>*/ command,
      {ProjectFilter filter, Combiner/*<T>*/ combine}) {
    return () =>
        graph.processDepthFirst(command, filter: filter, combine: combine);
  }

  _Processor/*<T>*/ _processor/*<T>*/(CommandConcurrencyMode mode) {
    switch (mode) {
      case CommandConcurrencyMode.serial:
        return _serialProcessor;
      case CommandConcurrencyMode.concurrentCommand:
      case CommandConcurrencyMode.concurrentProject:
      default:
        return _concurrentProcessor;
    }
  }

  Future/*<T>*/ process/*<T>*/(
      String taskDescription, SingleProjectCommand<S, dynamic/*=T*/ > command,
      {ProjectFilter filter,
      Combiner/*<T>*/ combine,
      CommandConcurrencyMode mode: CommandConcurrencyMode.concurrentCommand}) {
    final processor =
        _processor/*<T>*/(mode ?? CommandConcurrencyMode.concurrentCommand);

    return executeTask/*<T>*/(
        taskDescription,
        processor(
            (JefeProject project) =>
                _processOnSingeProject2(project, taskDescription, command),
            filter: filter,
            combine: combine));
  }

  Future/*<T>*/ processAllConcurrently/*<T>*/(
          String taskDescription, ProjectFunction/*<T>*/ command,
          {ProjectFilter filter, Combiner/*<T>*/ combine}) =>
      executeTask(
          taskDescription,
          () => graph.processAllConcurrently(
              (JefeProject project) =>
                  _processOnSingeProject(project, taskDescription, command),
              filter: filter,
              combine: combine));

  Future/*<T>*/ _processOnSingeProject/*<T>*/(JefeProject project,
          String taskDescription, ProjectFunction/*<T>*/ command) =>
      executeTask('$taskDescription for project ${project.name}',
          () => command(project));

  Future/*<T>*/ processAllConcurrently2/*<T>*/(String taskDescription,
          SingleProjectCommand<S, dynamic/*=T*/ > command,
          {ProjectFilter filter, Combiner/*<T>*/ combine}) =>
      executeTask(
          taskDescription,
          () => graph.processAllConcurrently(
              (JefeProject project) =>
                  _processOnSingeProject2(project, taskDescription, command),
              filter: filter,
              combine: combine));

  Future/*<T>*/ _processOnSingeProject2/*<T>*/(
          JefeProject project,
          String taskDescription,
          SingleProjectCommand<S, dynamic/*=T*/ > command) =>
      executeTask('$taskDescription for project ${project.name}',
          () async => command(await _singleProjectCommandFactory(project)));
}
