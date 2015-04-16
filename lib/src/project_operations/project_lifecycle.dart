library devops.project.operations.lifecycle;

import 'dart:async';
import 'package:devops/src/project.dart';
import 'package:devops/src/project_operations/git_feature.dart';

abstract class ProjectLifecycle {
  factory ProjectLifecycle(ProjectSource source,
      {GitFeatureCommandsFactory gitFeatureFactory}) {
    throw new StateError('Not implemented yet');
  }

  Future startNewFeature(String featureName,
      {bool doPush: false, bool recursive: true});

  // merge to develop, returns to git dependencies
  Future completeFeature(String featureName,
      {bool doPush: false, bool recursive: true});

  Future release(Iterable<Project> dependencies,
      {ReleaseType type: ReleaseType.minor});

//  Future deploy(); ????
}
