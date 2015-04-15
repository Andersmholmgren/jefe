library devops.project.operations.git;

import 'dart:async';
import 'package:devops/src/project.dart';

abstract class ProjectLifecycle {
  Future startNewFeature(String featureName,
      {bool doPush: false, bool recursive: true});

  // merge to develop, returns to git dependencies
  Future completeFeature(String featureName,
      {bool doPush: false, bool recursive: true});

  Future release(Iterable<Project> dependencies,
      {ReleaseType type: ReleaseType.minor});

//  Future deploy(); ????
}
