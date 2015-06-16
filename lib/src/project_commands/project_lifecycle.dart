// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.lifecycle;

import 'package:jefe/src/project_commands/git_feature.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'impl/project_lifecycle_impl.dart';
import 'package:jefe/src/project/release_type.dart';

/// High level commands relating to the project lifecycle
abstract class ProjectLifecycle {
  factory ProjectLifecycle(
      {GitFeatureCommandsFactory gitFeatureFactory}) = ProjectLifecycleImpl;

  ExecutorAwareProjectCommand init({bool doCheckout: true});

  /// A command to start a new feature, performing all the tasks necessary to
  /// put the projects within the group in the correct state, including the
  /// git branches, creating path dependencies etc
  CompositeProjectCommand startNewFeature(String featureName,
      {bool doPush: false, bool recursive: true});

  // Complete the feature by performing all the tasks necessary to return
  // the projects to the stable development state. Includes mergine git branches,
  // creating to git dependencies etc
  ProjectCommand completeFeature(String featureName,
      {bool doPush: false, bool recursive: true});

  /// Performs checks that things are in a healthy state for a release. e.g.
  /// make sure all tests pass
  CompositeProjectCommand preRelease({ReleaseType type: ReleaseType.minor});

  /// Create a release of the project group, including tagging, merging etc
  ProjectCommand release({ReleaseType type: ReleaseType.minor});
}
