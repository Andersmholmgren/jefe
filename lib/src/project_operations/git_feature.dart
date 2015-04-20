// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.operations.git.feature;

import 'impl/git_feature_impl.dart';
import 'package:jefe/src/project_operations/project_command.dart';

typedef GitFeatureCommands GitFeatureCommandsFactory();

GitFeatureCommands defaultFlowFeatureFactory() => new GitFeatureCommands();

abstract class GitFeatureCommands {
  factory GitFeatureCommands() = GitFeatureCommandsFlowImpl;
  String get developBranchName;
  ProjectCommand init();
  ProjectCommand featureStart(String featureName);
  ProjectCommand featureFinish(String featureName);
  ProjectDependencyGraphCommand currentFeatureName();
  ProjectCommand releaseStart(String version);
  ProjectCommand releaseFinish(String version);
}
