import 'package:jefe/src/project/jefe_project.dart';
import 'dart:async';
import 'dart:mirrors';

typedef Future<T> TFactory<T>(JefeProject project);

abstract class MultiProjectCommandSupport<C> {
  final C _singleT;
  final JefeProjectGraph _projectGraph;

//  final InstanceMirror _tMirror;
  final TFactory<C> _factory;

  MultiProjectCommandSupport(C singleT, this._projectGraph, this._factory) : this._singleT = singleT
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

    return _projectGraph.processDepthFirst(projectFunction);
  }
}

