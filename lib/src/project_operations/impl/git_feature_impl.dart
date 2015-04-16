library devops.project.operations.git.feature.impl;

import 'dart:async';
import 'package:devops/src/project_operations/git_feature.dart';
import 'package:devops/src/project_operations/impl/core.dart';
import 'package:devops/src/git/git.dart';
import 'package:logging/logging.dart';
import 'package:devops/src/project.dart';

Logger _log = new Logger('devops.project.operations.git.feature.impl');

/// implements [GitFeatureCommands] via git flow
class GitFeatureCommandsFlowImpl extends BaseCommand
    implements GitFeatureCommands {
  GitFeatureCommandsFlowImpl(ProjectSource projectSource)
      : super(projectSource);

  Future init() {
    return visitAllProjects('Initialising git flow', (Project p) async {
      await initGitFlow(await p.gitDir);
    });
  }
  Future featureStart(String featureName) {
    return visitAllProjects('Starting feature $featureName', (Project p) async {
      await gitFlowFeatureStart(await p.gitDir, featureName);
    });
  }
  Future featureFinish(String featureName) {
    return visitAllProjects('Finishing feature $featureName',
        (Project p) async {
      await gitFlowFeatureFinish(await p.gitDir, featureName);
    });
  }
  Future releaseStart(String version) {
    return visitAllProjects('Starting release $version', (Project p) async {
      await gitFlowReleaseStart(await p.gitDir, version);
    });
  }
  Future releaseFinish(String version) {
    return visitAllProjects('Finishing release $version', (Project p) async {
      await gitFlowReleaseFinish(await p.gitDir, version);
    });
  }
}
