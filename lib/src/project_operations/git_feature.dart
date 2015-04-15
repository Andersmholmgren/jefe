library devops.project.operations.git.feature;

import 'dart:async';

abstract class GitFeatureCommands {
  Future init();
  Future featureStart(String featureName);
  Future featureFinish(String featureName);
  Future releaseStart(String version);
  Future releaseFinish(String version);
}
