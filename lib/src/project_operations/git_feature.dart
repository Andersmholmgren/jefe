library devops.project.operations.git.feature;

import 'dart:async';
import 'package:devops/src/project.dart';
import 'impl/git_feature_impl.dart';
import 'package:devops/src/project_operations/project_command.dart';

typedef GitFeatureCommands GitFeatureCommandsFactory();

GitFeatureCommands defaultFlowFeatureFactory() => new GitFeatureCommands();

abstract class GitFeatureCommands {
  factory GitFeatureCommands() = GitFeatureCommandsFlowImpl;
  ProjectCommand<ProjectFunction> init();
  ProjectCommand<ProjectFunction> featureStart(String featureName);
  ProjectCommand<ProjectFunction> featureFinish(String featureName);
  ProjectCommand<ProjectFunction> releaseStart(String version);
  ProjectCommand<ProjectFunction> releaseFinish(String version);
}
