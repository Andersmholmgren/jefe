library devops.project.operations.git.feature;

import 'dart:async';
import 'package:devops/src/project.dart';
import 'impl/git_feature_impl.dart';

typedef GitFeatureCommands GitFeatureCommandsFactory(ProjectSource source);

abstract class GitFeatureCommands {
  factory GitFeatureCommands(ProjectSource source) = GitFeatureCommandsFlowImpl;
  Future init();
  Future featureStart(String featureName);
  Future featureFinish(String featureName);
  Future releaseStart(String version);
  Future releaseFinish(String version);
}
