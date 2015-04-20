// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.lifecycle;

import 'package:jefe/src/project_commands/git_feature.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'impl/project_lifecycle_impl.dart';
import 'package:jefe/src/project/release_type.dart';

abstract class ProjectLifecycle {
  factory ProjectLifecycle(
      {GitFeatureCommandsFactory gitFeatureFactory}) = ProjectLifecycleImpl;

  CompositeProjectCommand init();

  CompositeProjectCommand startNewFeature(String featureName,
      {bool doPush: false, bool recursive: true});

  // merge to develop, returns to git dependencies
  ProjectCommand completeFeature(String featureName,
      {bool doPush: false, bool recursive: true});

  ProjectCommand release({ReleaseType type: ReleaseType.minor});

//  Future deploy(); ????
}
