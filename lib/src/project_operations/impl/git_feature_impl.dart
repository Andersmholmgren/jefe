library devops.project.operations.git.feature.impl;

import 'dart:async';
import 'package:devops/src/project_operations/git_feature.dart';
import 'package:devops/src/project_operations/impl/core.dart';
import 'package:devops/src/git/git.dart';
import 'package:logging/logging.dart';
import 'package:devops/src/project.dart';
import 'package:devops/src/project_operations/project_command.dart';

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

class GitFeatureCommandsFlowImpl2 implements GitFeatureCommands2 {
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
