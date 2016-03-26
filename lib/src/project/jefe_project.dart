// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.jefe;

import 'dart:async';

import 'package:jefe/src/project/docker_commands.dart';
import 'package:jefe/src/project/git_commands.dart';
import 'package:jefe/src/project/git_feature.dart';
import 'package:jefe/src/project/process_commands.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project/project_lifecycle.dart';
import 'package:jefe/src/project/pub_commands.dart';
import 'package:jefe/src/project/pubspec_commands.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:option/option.dart';
import 'package:pubspec/pubspec.dart';
import 'package:pub_semver/pub_semver.dart';

/// A [Project] managed by Jefe
abstract class JefeProject extends Project implements JefeProjectGraph {
  JefeProjectSet get directDependencies;
  Set<JefeProject> get indirectDependencies;
  Set<JefeProject> get allDependencies;

  ProjectCommands get singleProjectCommands;

  /// Fetches the [PubSpec] as it was at the given [version]
  Future<PubSpec> pubSpecAsAt(Version version);

  Future<PubSpec> pubSpecAsAtSha(String sha);
}

/// Some function applied to a [JefeProject]
typedef Future<T> ProjectFunction<T>(JefeProject project);

typedef bool ProjectFilter(Project p);

typedef T Combiner<T>(T value, T element);

abstract class JefeGroupCommand<S> {
//  Future<S> singleProjectCommandFor(JefeProject project);
}

class ProjectCommands {
  final GitCommands git;
  final GitFeatureCommands gitFeature;
  final PubSpecCommands pubspecCommands;
  final PubCommands pub;
  final ProjectLifecycle lifecycle;
  final ProcessCommands processCommands;

  ProjectCommands(this.git, this.gitFeature, this.pubspecCommands, this.pub,
      this.lifecycle, this.processCommands);
}

class MultiProjectCommands extends ProjectCommands {
  final DockerCommands docker;

  MultiProjectCommands(
      GitCommands git,
      GitFeatureCommands gitFeature,
      PubSpecCommands pubspecCommands,
      PubCommands pub,
      ProjectLifecycle lifecycle,
      ProcessCommands processCommands,
      this.docker)
      : super(
            git, gitFeature, pubspecCommands, pub, lifecycle, processCommands);
}

/// A graph of [JefeProject] ordered by their dependencies
abstract class JefeProjectGraph implements ProjectCommands {
  /// Navigates the graph of [JefeProject] depthFirst such that those
  /// with no dependencies are returned first and those projects that are
  /// depended upon by other projects are returned before those projects
  Iterable<JefeProject> get depthFirst;

  Iterable<JefeProject> getDepthFirst(Set<JefeProject> visited);

  /// returns a [JefeProject] with matching name that is either this project
  /// or one of it's dependencies (direct or indirect)
  Option<JefeProject> getProjectByName(String projectName);

  /// Iterates over [depthFirst] invoking [command] for each
  Future/*<T>*/ processDepthFirst/*<T>*/(ProjectFunction/*<T>*/ command,
      {ProjectFilter filter, Combiner/*<T>*/ combine});

  /// Invokes [command] on this project and all reachable dependencies.
  /// [command] is executed concurrently on all projects.
  /// An optional [filter] can be provided to limit which projects the [command]
  /// is executed on.
  Future/*<T>*/ processAllConcurrently/*<T>*/(ProjectFunction/*<T>*/ command,
      {ProjectFilter filter, Combiner/*<T>*/ combine});

  /// Invokes [command] on this project and all reachable dependencies
  /// [command] is executed one project at a time.
  /// An optional [filter] can be provided to limit which projects the [command]
  /// is executed on.
  Future/*<T>*/ processAllSerially/*<T>*/(ProjectFunction/*<T>*/ command,
      {ProjectFilter filter, Combiner/*<T>*/ combine});

  MultiProjectCommands multiProjectCommands(
      {CommandConcurrencyMode defaultConcurrencyMode,
      ProjectFilter projectFilter});
}

/// A [Set] of [JefeProject] that supports [JefeProjectGraph] operations
abstract class JefeProjectSet implements Set<JefeProject>, JefeProjectGraph {}
