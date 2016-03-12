import 'package:jefe/src/project/jefe_project.dart';
import 'dart:async';
import 'dart:mirrors';
import 'package:logging/logging.dart';
import 'package:jefe/src/project_commands/project_command.dart';

Logger _log = new Logger('jefe.project.command.multiproject');

typedef Future<T> SingleProjectCommandFactory<T>(JefeProject project);

/**
 * TODO: we could build a default mode into JefeProject / JefeProjectGraph etc
 * that determines whether the methods will respond in a multi or single
 * project manner.
 */

class MultiProjectCommandSupport<C> {
  final JefeProjectGraph _projectGraph;

//  final InstanceMirror _tMirror;
  final SingleProjectCommandFactory<C> _factory;

  MultiProjectCommandSupport(this._projectGraph, this._factory)
//      : this._singleT = singleT
//  ,        _tMirror = reflect(singleT)
  ;

  noSuchMethod(Invocation i) {
    /**
     * TODO: this is also useful for wrapping single project commands.
     * i.e. we wrap so we can log, time, catch errors etc!!!!!
     *
     * That way commands are written in the simplest possible manner, but we
     * can still have all that goodness with it in a standard way. Yay
     */

    Future/*<A>*/ projectFunction/*<A>*/(JefeProject project) async {
//      _log.fine('Executing ${i.memberName}');
      final C t = await _factory(project);
      final InstanceMirror tMirror = reflect(t);
      return tMirror.delegate(i) as Future/*<A>*/;
    }

    /**
     * TODO: don't assume depth first. Support all variants somehow.
     *
     * Maybe use annotations to mark commands that can't be run in parallel,
     * or that must run depthFirst. Mind you distinguishing between serial
     * and depthFirst is fairly meaningless
     */
    return _projectGraph.processDepthFirst(projectFunction);
  }
}

class SingleProjectCommandSupport<C> {
  final JefeProject _project;
  final SingleProjectCommandFactory<C> _singleProjectCommandFactory;
  InstanceMirror __singleProjectCommandMirror;

  Future<InstanceMirror> get _singleProjectCommandMirror async =>
      __singleProjectCommandMirror ??=
          reflect(await _singleProjectCommandFactory(_project));

  SingleProjectCommandSupport(this._singleProjectCommandFactory, this._project);

  noSuchMethod(Invocation i) {
    return executeTask(
        '${MirrorSystem.getName(i.memberName)} on project ${_project.name}',
        () async {
      return (await _singleProjectCommandMirror).delegate(i);
    });
  }
}
