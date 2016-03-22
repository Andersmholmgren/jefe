// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.lifecycle;

import 'dart:async';

import 'package:jefe/src/project/release_type.dart';

/// High level commands relating to the project lifecycle
abstract class ProjectLifecycle {
  Future init({bool doCheckout: true});

  /// A command to start a new feature, performing all the tasks necessary to
  /// put the projects within the group in the correct state, including the
  /// git branches, creating path dependencies etc
  Future startNewFeature(String featureName, {bool doPush: false});

  // Complete the feature by performing all the tasks necessary to return
  // the projects to the stable development state. Includes merging git branches,
  // creating to git dependencies etc
  Future completeFeature({String featureName});

  /// Performs checks that things are in a healthy state for a release. e.g.
  /// make sure all tests pass
  Future preRelease(
      {ReleaseType type: ReleaseType.minor,
      bool autoUpdateHostedVersions: false});

  /// Create a release of the project group, including tagging, merging etc
  Future release(
      {ReleaseType type: ReleaseType.minor,
      bool autoUpdateHostedVersions: false});
}
