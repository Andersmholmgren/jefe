library devops.project.operations.lifecycle;

import 'package:devops/src/project.dart';
import 'package:devops/src/project_operations/git_feature.dart';
import 'package:devops/src/project_operations/project_command.dart';
import 'impl/project_lifecycle_impl.dart';

abstract class ProjectLifecycle {
  factory ProjectLifecycle(
      {GitFeatureCommandsFactory gitFeatureFactory}) = ProjectLifecycleImpl;

  CompositeProjectCommand startNewFeature(String featureName,
      {bool doPush: false, bool recursive: true});

  // merge to develop, returns to git dependencies
  CompositeProjectCommand completeFeature(String featureName,
      {bool doPush: false, bool recursive: true});

  ProjectCommand release({ReleaseType type: ReleaseType.minor});

//  Future deploy(); ????
}
