// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.pub.spec;

import 'dart:async';

import 'package:pubspec/pubspec.dart';

/// Commands that operate on each [Project]s [PubSpec] files
abstract class PubSpecCommands {
  /// Sets the dependencies between [Project]s within the group to use path
  /// dependencies
  Future setToPathDependencies();

  /// Sets the dependencies between [Project]s within the group to use git
  /// dependencies, based on the current commit hash of the respective projects
  Future setToGitDependencies();

  /// Sets the dependencies between [Project]s within the group to use hosted
  /// dependencies (if the package is hosted).
  ///
  /// If not hosted then will fall back to git if [useGitIfNotHosted] is true
  /// or throw an error otherwise
  Future setToHostedDependencies({bool useGitIfNotHosted: true});

  // TODO: this only makes sense to run on a single project at a time, so
  // making it a command is kinda weird
  Future<bool> haveDependenciesChanged(DependencyType type,
      {bool useGitIfNotHosted: true});
}

enum DependencyType { path, git, hosted }
