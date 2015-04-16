library devops.project.operations.git.feature;

import 'dart:async';
import 'package:devops/src/project.dart';
import 'impl/git_feature_impl.dart';
import 'package:devops/src/project_operations/project_command.dart';

typedef GitFeatureCommands GitFeatureCommandsFactory(ProjectSource source);

GitFeatureCommands defaultFlowFeatureFactory(ProjectSource source) =>
    new GitFeatureCommands(source);

abstract class GitFeatureCommands {
  factory GitFeatureCommands(ProjectSource source) = GitFeatureCommandsFlowImpl;
  Future init();
  Future featureStart(String featureName);
  Future featureFinish(String featureName);
  Future releaseStart(String version);
  Future releaseFinish(String version);
}

abstract class GitFeatureCommands2 {
//  factory GitFeatureCommands2(ProjectSource source) = GitFeatureCommandsFlowImpl;
  ProjectCommand<ProjectFunction> init();
  ProjectCommand<ProjectFunction> featureStart(String featureName);
  ProjectCommand<ProjectFunction> featureFinish(String featureName);
  ProjectCommand<ProjectFunction> releaseStart(String version);
  ProjectCommand<ProjectFunction> releaseFinish(String version);
}
