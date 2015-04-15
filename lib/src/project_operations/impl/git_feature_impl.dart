library devops.project.operations.git.feature.impl;

import 'dart:async';
import 'package:devops/src/project_operations/git_feature.dart';
import 'package:devops/src/project_operations/impl/core.dart';
import 'package:devops/src/git/git.dart';
import 'package:logging/logging.dart';
import 'package:devops/src/project.dart';

Logger _log = new Logger('devops.project.impl');

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
  Future featureStart(String featureName) {}
  Future featureFinish(String featureName) {}
  Future releaseStart(String version) {}
  Future releaseFinish(String version) {}
}
