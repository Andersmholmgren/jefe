library devops.project.operations.git.feature;

import 'impl/git_feature_impl.dart';
import 'package:devops/src/project_operations/project_command.dart';

typedef GitFeatureCommands GitFeatureCommandsFactory();

GitFeatureCommands defaultFlowFeatureFactory() => new GitFeatureCommands();

abstract class GitFeatureCommands {
  factory GitFeatureCommands() = GitFeatureCommandsFlowImpl;
  ProjectCommand init();
  ProjectCommand featureStart(String featureName);
  ProjectCommand featureFinish(String featureName);
  ProjectCommand releaseStart(String version);
  ProjectCommand releaseFinish(String version);
}
