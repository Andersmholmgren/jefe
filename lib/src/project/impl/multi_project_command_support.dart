import 'dart:async';
import 'dart:mirrors';

import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:logging/logging.dart';

Logger _log = new Logger('jefe.project.command.multiproject');

typedef Future<T> SingleProjectCommandFactory<T>(JefeProject project);
typedef Future<T> SingleProjectCommand<S, T>(S single);
typedef Callable<T> _Processor<T>(ProjectFunction<T> command,
    {ProjectFilter filter, Combiner<T> combine});

/**
 * TODO: we could build a default mode into JefeProject / JefeProjectGraph etc
 * that determines whether the methods will respond in a multi or single
 * project manner.
 */

class MultiProjectCommandSupport<C> extends Object with CommandSupport {
  final JefeProjectGraph graph;

  final SingleProjectCommandFactory<C> singleProjectCommandFactory;

  final CommandConcurrencyMode defaultConcurrencyMode;
  final ProjectFilter projectFilter;

  MultiProjectCommandSupport(this.graph, this.singleProjectCommandFactory,
      {this.defaultConcurrencyMode: CommandConcurrencyMode.concurrentCommand,
      ProjectFilter projectFilter})
      : this.projectFilter = projectFilter ?? ((Project p) => true);

  noSuchMethod(Invocation i) {
    /**
     * TODO: this is also useful for wrapping single project commands.
     * i.e. we wrap so we can log, time, catch errors etc!!!!!
     *
     * That way commands are written in the simplest possible manner, but we
     * can still have all that goodness with it in a standard way. Yay
     */

    Future<T> projectFunction<T>(JefeProject project) async {
//      _log.fine('Executing ${i.memberName}');
      final C singleProjectCommand = await singleProjectCommandFactory(project);
      final InstanceMirror singleProjectCommandMirror =
          reflect(singleProjectCommand);
      return singleProjectCommandMirror.delegate(i) as Future<T>;
    }

    /**
     * TODO: Maybe use annotations to mark commands that can't be run in parallel,
     * or that must run depthFirst. Mind you distinguishing between serial
     * and depthFirst is fairly meaningless
     */

    return process(MirrorSystem.getName(i.memberName), projectFunction,
        mode: defaultConcurrencyMode, filter: projectFilter);
  }
}

abstract class CommandSupport {
  JefeProjectGraph get graph;

  Future<T> process<T>(
      String taskDescription,
//    SingleProjectCommand<S, dynamic/*=T*/ > command,
      ProjectFunction<T> command,
      {ProjectFilter filter,
      Combiner<T> combine,
      CommandConcurrencyMode mode: CommandConcurrencyMode.concurrentCommand}) {
    final processor =
        _processor<T>(mode ?? CommandConcurrencyMode.concurrentCommand);

    return executeTask<T>(
        taskDescription, processor(command, filter: filter, combine: combine));
  }

//  Future<T> processDepthFirst<T>(ProjectFunction<T> command,
//          {ProjectFilter filter, Combiner<T> combine}) =>
//      graph.processDepthFirst(command, filter: filter, combine: combine);

  Callable<T> _concurrentProcessor<T>(ProjectFunction<T> command,
      {ProjectFilter filter, Combiner<T> combine}) {
    return () =>
        graph.processAllConcurrently(command, filter: filter, combine: combine);
  }

  Callable<T> _serialProcessor<T>(ProjectFunction<T> command,
      {ProjectFilter filter, Combiner<T> combine}) {
    return () =>
        graph.processDepthFirst(command, filter: filter, combine: combine);
  }

//  Callable<T> _singleProjectProcessor<T>(ProjectFunction<T> command,
//      {ProjectFilter filter, Combiner<T> combine}) {
//    return () {
//      final project = graph as JefeProject;
//      if (!filter(project)) {
//        return new Future.value();
//      }
//      return command(project);
//    };
//  }

  _Processor<T> _processor<T>(CommandConcurrencyMode mode) {
//    if (isSingleProjectMode) {
//      return _singleProjectProcessor;
//    }

    switch (mode) {
      case CommandConcurrencyMode.serialDepthFirst:
        return _serialProcessor;
      case CommandConcurrencyMode.concurrentCommand:
      case CommandConcurrencyMode.concurrentProject:
      default:
        return _concurrentProcessor;
    }
  }
}

// can't get this to work in Dart 2
//class SingleProjectCommandSupport<C> {
//  final JefeProject _project;
//  final SingleProjectCommandFactory<C> _singleProjectCommandFactory;
//  InstanceMirror __singleProjectCommandMirror;
//
//  Future<InstanceMirror> get _singleProjectCommandMirror async =>
//      __singleProjectCommandMirror ??=
//          reflect(await _singleProjectCommandFactory(_project));
//
//  SingleProjectCommandSupport(this._singleProjectCommandFactory, this._project);
//
//  noSuchMethod(Invocation i) {
//    return executeTask(
//        '${MirrorSystem.getName(i.memberName)} on project ${_project.name}',
//        () async => (await _singleProjectCommandMirror).delegate(i));
//  }
//}

abstract class SingleProjectCommandSupport<C> {
  final JefeProject project;
  final SingleProjectCommandFactory<C> _singleProjectCommandFactory;

//  Future<InstanceMirror> get _singleProjectCommandMirror async =>
//      __singleProjectCommandMirror ??=
//          reflect(await _singleProjectCommandFactory(project));

  Future<C> get decoratee async => _singleProjectCommandFactory(project);

  SingleProjectCommandSupport(this._singleProjectCommandFactory, this.project);

  Future<T> doExecuteTask<T>(String functionName, Future<T> f(C c)) =>
      executeTask<T>(
          '$functionName on project ${project.name}', () => decoratee.then(f));

//  noSuchMethod(Invocation i) {
//    return executeTask(
//        '${MirrorSystem.getName(i.memberName)} on project ${project.name}',
//        () async => (await _singleProjectCommandMirror).delegate(i));
//  }
}
