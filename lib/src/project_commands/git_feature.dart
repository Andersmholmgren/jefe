// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.git.feature;

import 'impl/git_feature_impl.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:git/git.dart';

typedef GitFeatureCommands GitFeatureCommandsFactory();

GitFeatureCommands defaultFlowFeatureFactory() => new GitFeatureCommands();

/// Defines the commands that relate to the branching strategy for developing
/// and releasing features
abstract class GitFeatureCommands {
  factory GitFeatureCommands() = GitFeatureCommandsFlowImpl;

  /// The branch that features merge onto when they complete
  String get developBranchName;

  /// Performs any initialisation such as defining the names of directories etc
  /// to be used
  ProjectCommand init();

  /// Creates a new feature branch based on the [featureName]
  ProjectCommand featureStart(String featureName);

  /// Merges the feature branch back on to the [developBranchName].
  /// Optionally [excludeOnlyCommitIf] may be passed to exclude an automatically
  /// generated commit on feature start if that is the only commit on the
  /// feature branch
  ProjectCommand featureFinish(String featureName,
      {bool excludeOnlyCommitIf(Commit commit)});

  /// Looks up the name of the current feature branch if any. Note it is an
  /// error if different projects are on different feature branches
  ProjectDependencyGraphCommand currentFeatureName();

  /// Initates a release which may involve creating a release branch
  ProjectCommand releaseStart(String version);

  /// Completes a release which may involve merging the development branch
  /// on a master branch and tagging the version.
  ProjectCommand releaseFinish(String version);
}
