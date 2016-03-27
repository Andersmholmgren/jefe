// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.jefe.impl;

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:jefe/src/project/git_commands.dart';
import 'package:jefe/src/project/git_feature.dart';
import 'package:jefe/src/project/impl/docker_commands_impl.dart';
import 'package:jefe/src/project/impl/git_commands_impl.dart';
import 'package:jefe/src/project/impl/git_feature_impl.dart';
import 'package:jefe/src/project/impl/process_commands_impl.dart';
import 'package:jefe/src/project/impl/project_impl.dart';
import 'package:jefe/src/project/impl/project_lifecycle_impl.dart';
import 'package:jefe/src/project/impl/pub_commands_impl.dart';
import 'package:jefe/src/project/impl/pubspec_commands_impl.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project/process_commands.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project/project_lifecycle.dart';
import 'package:jefe/src/project/pub_commands.dart';
import 'package:jefe/src/project/pubspec_commands.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:pub_semver/src/version.dart';
import 'package:pubspec/pubspec.dart';
import 'package:quiver/iterables.dart';

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
            (JefeProject p) => createGitFeatureCommands(p)),
        super(gitUri, installDirectory, pubspec, hostedMode);

  JefeProjectImpl.from(
      Iterable<JefeProject> directDependencies, Project project,
      {GitFeatureCommandsFactory gitFeatureCommandsFactory})
      : this(
            new JefeProjectSetImpl(
                directDependencies.toSet(), project.installDirectory.parent),
            project.gitUri,
            project.installDirectory,
            project.pubspec,
            project.hostedMode,
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

  ProjectCommands _singleProjectCommands;
  @override
  ProjectCommands get singleProjectCommands {
    ProjectCommands create() {
      return new ProjectCommands(
          createGitCommands(this, multiProject: false),
          createGitFeatureCommands(this, multiProject: false),
          createPubSpecCommands(this, multiProject: false),
          createPubCommands(this, multiProject: false),
          createProjectLifecycle(this, multiProject: false),
          createProcessCommands(this, multiProject: false));
    }

    return _singleProjectCommands ??= create();
  }

  @override
  Directory get _dockerRootDirectory => installDirectory;

  @override
  Future<PubSpec> pubSpecAsAt(Version version) async =>
      new PubSpec.fromYamlString(await singleProjectCommands.git
          .fetchFileContentsAtVersion(version, 'pubspec.yaml'));

  @override
  Future<PubSpec> pubSpecAsAtSha(String sha) async =>
      new PubSpec.fromYamlString(await singleProjectCommands.git
          .fetchFileContentsAtSha(sha, 'pubspec.yaml'));
}

class JefeProjectSetImpl extends DelegatingSet<JefeProject>
    with _JefeProjectGraphMixin
    implements JefeProjectSet {
  final Directory _dockerRootDirectory;

  JefeProjectSetImpl(Set<JefeProject> base, this._dockerRootDirectory)
      : super(base);

  Option<JefeProject> getProjectByName(String projectName) =>
      map /**<Option<JefeProject>>*/ ((c) => c.getProjectByName(projectName))
          .firstWhere((o) => o is Some, orElse: () => const None())
      as Option<JefeProject>;

  Iterable<JefeProject> getDepthFirst(Set<JefeProject> visited) =>
      expand /**<JefeProject>*/ ((n) => n.getDepthFirst(visited))
      as Iterable<JefeProject>;
}

abstract class _JefeProjectGraphMixin implements JefeProjectGraph {
  Directory get _dockerRootDirectory;

  Iterable<JefeProject> get depthFirst => getDepthFirst(new Set<JefeProject>());

  Iterable<JefeProject> _filteredDepthFirst(ProjectFilter filter) =>
      depthFirst.where(filter ?? _noOpFilter);

  Future/*<T>*/ processDepthFirst/*<T>*/(ProjectFunction/*<T>*/ command,
      {ProjectFilter filter, Combiner/*<T>*/ combine}) async {
    return await new Stream<JefeProject>.fromIterable(
            _filteredDepthFirst(filter))
        .asyncMap((JefeProject p) => command(p))
        .fold(null, _combinerToFold(combine ?? _takeLast));
//    return await Future.forEach(
//        _filteredDepthFirst(filter), (JefeProject p) => command(p));
  }

  Future/*<T>*/ processAllConcurrently/*<T>*/(ProjectFunction/*<T>*/ command,
      {ProjectFilter filter, Combiner/*<T>*/ combine}) async {
    return new Stream/*<T>*/ .fromFutures(
            _filteredDepthFirst(filter).map/*<Future<T>>*/(command))
        .fold(null, _combinerToFold(combine ?? _takeLast));
  }

  Future/*<T>*/ processAllSerially/*<T>*/(ProjectFunction/*<T>*/ command,
          {ProjectFilter filter, Combiner/*<T>*/ combine}) =>
      processDepthFirst(command, filter: filter, combine: combine);

  @override
  GitCommands get git => defaultMultiProjectCommands.git;

  @override
  GitFeatureCommands get gitFeature => defaultMultiProjectCommands.gitFeature;

  @override
  PubSpecCommands get pubspecCommands =>
      defaultMultiProjectCommands.pubspecCommands;

  @override
  PubCommands get pub => defaultMultiProjectCommands.pub;

  @override
  ProjectLifecycle get lifecycle => defaultMultiProjectCommands.lifecycle;

  @override
  ProcessCommands get processCommands =>
      defaultMultiProjectCommands.processCommands;

  @override
  MultiProjectCommands multiProjectCommands(
      {CommandConcurrencyMode defaultConcurrencyMode,
      ProjectFilter projectFilter}) {
    return new MultiProjectCommands(
        createGitCommands(this,
            multiProject: true,
            defaultConcurrencyMode: defaultConcurrencyMode,
            projectFilter: projectFilter),
        createGitFeatureCommands(this,
            multiProject: true,
            defaultConcurrencyMode: defaultConcurrencyMode,
            projectFilter: projectFilter),
        createPubSpecCommands(this,
            multiProject: true,
            defaultConcurrencyMode: defaultConcurrencyMode,
            projectFilter: projectFilter),
        createPubCommands(this,
            multiProject: true,
            defaultConcurrencyMode: defaultConcurrencyMode,
            projectFilter: projectFilter),
        createProjectLifecycle(this,
            multiProject: true,
            defaultConcurrencyMode: defaultConcurrencyMode,
            projectFilter: projectFilter),
        createProcessCommands(this,
            multiProject: true,
            defaultConcurrencyMode: defaultConcurrencyMode,
            projectFilter: projectFilter),
        createDockerCommands(this,
            _dockerRootDirectory, // TODO: not sure if it is this or the container dir
            multiProject: false));
  }

  MultiProjectCommands _defaultMultiProjectCommands;
//  @override
  MultiProjectCommands get defaultMultiProjectCommands =>
      _defaultMultiProjectCommands ??= multiProjectCommands();
}

bool _noOpFilter(Project p) => true;

/*=T*/ _takeLast/*<T>*/(/*=T*/ value, /*=T*/ element) => element;

//const Object _marker = const Object();

// workaround the fact that reduce blows up when no results.
// So run a fold instead but hide it from the caller
Combiner/*<T>*/ _combinerToFold/*<T>*/(Combiner/*<T>*/ combiner) {
  var/*=T*/ firstValue;
  bool seenFirst = false;
  bool seenSecond = false;
  return (/*=T*/ value, /*=T*/ element) {
    if (!seenFirst) {
      seenFirst = true;
      firstValue = element;
      return firstValue;
    } else {
      if (!seenSecond) {
        seenSecond = true;
        return combiner(firstValue, element);
      } else {
        return combiner(value, element);
      }
    }
//    return element != _marker ? combiner(value, element) :
  };
}
