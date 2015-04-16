library devops.project.operations.git.feature.impl;

import 'package:devops/src/project_operations/git_feature.dart';
import 'package:devops/src/git/git.dart';
import 'package:logging/logging.dart';
import 'package:devops/src/project.dart';
import 'package:devops/src/project_operations/project_command.dart';

Logger _log = new Logger('devops.project.operations.git.feature.impl');

class GitFeatureCommandsFlowImpl implements GitFeatureCommands {
  ProjectCommand<ProjectFunction> init() => projectCommand('git flow init',
      (Project p) async {
    await initGitFlow(await p.gitDir);
  });

  ProjectCommand<ProjectFunction> featureStart(String featureName) =>
      projectCommand('git flow feature start', (Project p) async {
    await gitFlowFeatureStart(await p.gitDir, featureName);
  });

  ProjectCommand<ProjectFunction> featureFinish(String featureName) =>
      projectCommand('git flow feature finish', (Project p) async {
    await gitFlowFeatureFinish(await p.gitDir, featureName);
  });

  ProjectCommand<ProjectFunction> releaseStart(String releaseName) =>
      projectCommand('git flow release start', (Project p) async {
    await gitFlowReleaseStart(await p.gitDir, releaseName);
  });

  ProjectCommand<ProjectFunction> releaseFinish(String releaseName) =>
      projectCommand('git flow release finish', (Project p) async {
    await gitFlowReleaseFinish(await p.gitDir, releaseName);
  });
}
