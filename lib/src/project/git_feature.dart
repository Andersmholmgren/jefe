// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.git.feature;

import 'dart:async';

import 'package:git/git.dart';
import 'package:pub_semver/pub_semver.dart';

/// Defines the commands that relate to the branching strategy for developing
/// and releasing features
abstract class GitFeatureCommands {
  /// The branch that features merge onto when they complete
  String get developBranchName;

  /// Performs any initialisation such as defining the names of directories etc
  /// to be used
  Future init();

  /// Creates a new feature branch based on the [featureName]
  /// If [throwIfExists] is true then it is treated as an error if the feature
  /// branch already exists. Otherwise, it will check out the feature branch.
  /// TODO: Ideally we should check that the feature branch is correctly based
  /// off the develop branch and either throw, merge or rebase otherwise
  Future featureStart(String featureName, {bool throwIfExists: false});

  /// Merges the feature branch back on to the [developBranchName].
  /// Optionally [excludeOnlyCommitIf] may be passed to exclude an automatically
  /// generated commit on feature start if that is the only commit on the
  /// feature branch
  Future featureFinish(String featureName,
      {bool excludeOnlyCommitIf(Commit commit)});

  /// Looks up the name of the current feature branch if any. Note it is an
  /// error if different projects are on different feature branches
  Future currentFeatureName();

  /// Initiates a release which may involve creating a release branch
  Future releaseStart(String version);

  /// Completes a release which may involve merging the development branch
  /// on a master branch and tagging the version.
  Future releaseFinish(String version);

  /// Fetch release version tags
  Future<Iterable<Version>> getReleaseVersionTags();

  Future assertNoActiveReleases();
}
