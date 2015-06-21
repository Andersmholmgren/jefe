// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.pub.spec;

import 'package:jefe/src/project_commands/project_command.dart';
import 'impl/pubspec_commands_impl.dart';
import 'package:pubspec/pubspec.dart';

/// Commands that operate on each [Project]s [PubSpec] files
abstract class PubSpecCommands {
  factory PubSpecCommands() = PubSpecCommandsImpl;

  /// Sets the dependencies between [Project]s within the group to use path
  /// dependencies
  ProjectCommand setToPathDependencies();

  /// Sets the dependencies between [Project]s within the group to use git
  /// dependencies, based on the current commit hash of the respective projects
  ProjectCommand setToGitDependencies();

  /// Sets the dependencies between [Project]s within the group to use hosted
  /// dependencies (if the package is hosted).
  ///
  /// If not hosted then will fall back to git if [useGitIfNotHosted] is true
  /// or throw an error otherwise
  ProjectCommand setToHostedDependencies({bool useGitIfNotHosted: true});
}
