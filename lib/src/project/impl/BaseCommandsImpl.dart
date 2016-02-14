import 'package:jefe/src/project/jefe_project.dart';
import 'dart:async';
import 'package:jefe/src/project_commands/project_command.dart'
    show executeTask;

abstract class BaseCommandsImpl {
  final JefeProjectGraph graph;

  BaseCommandsImpl(this.graph);

  /// Iterates over [depthFirst] invoking [command] for each
  Future/*<T>*/ processDepthFirst/*<T>*/(ProjectFunction/*<T>*/ command,
          {ProjectFilter filter, Combiner/*<T>*/ combine}) =>
      graph.processDepthFirst(command, filter: filter, combine: combine);

  /// Invokes [command] on this project and all reachable dependencies.
  /// [command] is executed concurrently on all projects.
  /// An optional [filter] can be provided to limit which projects the [command]
  /// is executed on.
  Future/*<T>*/ processAllConcurrently/*<T>*/(
          String taskDescription, ProjectFunction/*<T>*/ command,
          {ProjectFilter filter, Combiner/*<T>*/ combine}) =>
      executeTask(
          taskDescription,
          () => graph.processAllConcurrently(command,
              filter: filter, combine: combine));
}
