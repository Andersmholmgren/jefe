// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.jefe.impl;

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:jefe/src/project/git_commands.dart';
import 'package:jefe/src/project/git_feature.dart';
import 'package:jefe/src/project/impl/git_commands_impl.dart';
import 'package:jefe/src/project/impl/git_feature_impl.dart';
import 'package:jefe/src/project/impl/project_impl.dart';
import 'package:jefe/src/project/impl/pub_commands_impl.dart';
import 'package:jefe/src/project/impl/pubspec_commands_impl.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project/pub_commands.dart';
import 'package:jefe/src/project/pubspec_commands.dart';
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:pubspec/pubspec.dart';
import 'package:quiver/iterables.dart';
import 'package:jefe/src/project/project_lifecycle.dart';
import 'package:jefe/src/project/impl/project_lifecycle_impl.dart';

Logger _log = new Logger('jefe.project.jefe.impl');

class JefeProjectImpl extends ProjectImpl
    with _JefeProjectGraphMixin
    implements JefeProject, JefeProjectGraph {
  final GitFeatureCommandsFactory _gitFeatureCommandsFactory;

  @override
  final JefeProjectSet directDependencies;

  @override
  Set<JefeProject> get allDependencies =>
      getDepthFirst(new Set<JefeProject>()).toSet();

  @override
  Set<JefeProject> get indirectDependencies =>
      allDependencies.difference(directDependencies);

  JefeProjectImpl(this.directDependencies, String gitUri,
      Directory installDirectory, PubSpec pubspec, HostedMode hostedMode,
      {GitFeatureCommandsFactory gitFeatureCommandsFactory})
      : this._gitFeatureCommandsFactory = (gitFeatureCommandsFactory ??
            (JefeProject p) => new GitFeatureCommandsFlowImpl(p)),
        super(gitUri, installDirectory, pubspec, hostedMode);

  JefeProjectImpl.from(Set<JefeProject> directDependencies, Project project,
      {GitFeatureCommandsFactory gitFeatureCommandsFactory})
      : this(directDependencies, project.gitUri, project.installDirectory,
            project.pubspec, project.hostedMode,
            gitFeatureCommandsFactory: gitFeatureCommandsFactory);

  @override
  Iterable<JefeProject> getDepthFirst(Set<JefeProject> visited) {
    final children = directDependencies.getDepthFirst(visited);

    Iterable<JefeProject> us() sync* {
      if (!visited.contains((this))) {
        visited.add(this);
        yield this;
      }
    }

    return concat(<Iterable<JefeProject>>[children, us()])
        as Iterable<JefeProject>;
  }

  @override
  Option<JefeProject> getProjectByName(String projectName) =>
      name == projectName
          ? new Some<JefeProject>(this)
          : directDependencies.getProjectByName(projectName);

  GitCommands _git;

  @override
  GitCommands get git => _git ??= createGitCommands(this);

//  GitCommands _gitCurrentProject;

//  @override
//  Future<GitCommands> get gitCurrentProject async => _gitCurrentProject ??=
//      new GitCommandsSingleProjectImpl(this, await gitDir);

  GitFeatureCommands _gitFeature;

  @override
  GitFeatureCommands get gitFeature =>
      _gitFeature ??= _gitFeatureCommandsFactory(this);

  PubSpecCommands _pubspecCommands;

  @override
  PubSpecCommands get pubspecCommands =>
      _pubspecCommands ??= new PubSpecCommandsImpl(this);

  PubCommands _pub;

  @override
  PubCommands get pub => _pub ??= new PubCommandsImpl(this);

  ProjectLifecycle _lifecycle;

  @override
  ProjectLifecycle get lifecycle =>
      _lifecycle ??= new ProjectLifecycleMultiProjectImpl(this);

  ProjectCommands _singleProjectCommands;

  @override
  ProjectCommands get singleProjectCommands {
    ProjectCommands create() {
      return new ProjectCommands(
          createGitCommands(this, multiProject: false),
          createGitFeatureCommands(this, multiProject: false),
          null,
          createPubCommands(this, multiProject: false),
          createProjectLifecycle(this, multiProject: false));
    }

    return _singleProjectCommands ??= create();
  }
}

class JefeProjectSetImpl extends DelegatingSet<JefeProject>
    with _JefeProjectGraphMixin
    implements JefeProjectSet {
  JefeProjectSetImpl(Set<JefeProject> base) : super(base);

  Option<JefeProject> getProjectByName(String projectName) =>
      map /**<Option<JefeProject>>*/ ((c) => c.getProjectByName(projectName))
          .firstWhere((o) => o is Some, orElse: () => const None())
      as Option<JefeProject>;

  Iterable<JefeProject> getDepthFirst(Set<JefeProject> visited) =>
      expand /**<JefeProject>*/ ((n) => n.getDepthFirst(visited))
      as Iterable<JefeProject>;
}

abstract class _JefeProjectGraphMixin implements JefeProjectGraph {
  Iterable<JefeProject> get depthFirst => getDepthFirst(new Set<JefeProject>());

  Iterable<JefeProject> _filteredDepthFirst(ProjectFilter filter) =>
      depthFirst.where(filter ?? _noOpFilter);

  Future/*<T>*/ processDepthFirst/*<T>*/(ProjectFunction/*<T>*/ command,
      {ProjectFilter filter, Combiner/*<T>*/ combine}) async {
    return await new Stream<JefeProject>.fromIterable(
            _filteredDepthFirst(filter))
        .asyncMap((JefeProject p) => command(p))
        .reduce(combine ?? _takeLast) as Future/*<T>*/;
//    return await Future.forEach(
//        _filteredDepthFirst(filter), (JefeProject p) => command(p));
  }

  Future/*<T>*/ processAllConcurrently/*<T>*/(ProjectFunction/*<T>*/ command,
      {ProjectFilter filter, Combiner/*<T>*/ combine}) async {
    return new Stream/*<T>*/ .fromFutures(
            _filteredDepthFirst(filter).map/*<Future<T>>*/(command))
        .reduce(combine ?? _takeLast) as Future/*<T>*/;
//    return (await Future.wait(_filteredDepthFirst(filter).map(command)))
//        .reduce(combine ?? _takeLast);
  }

  Future/*<T>*/ processAllSerially/*<T>*/(ProjectFunction/*<T>*/ command,
          {ProjectFilter filter, Combiner/*<T>*/ combine}) =>
      processDepthFirst(command, filter: filter, combine: combine);
}

bool _noOpFilter(Project p) => true;

/*=T*/ _takeLast/*<T>*/(/*=T*/ value, /*=T*/ element) => element;
