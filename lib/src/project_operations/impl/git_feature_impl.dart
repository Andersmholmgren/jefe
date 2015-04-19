library devops.project.operations.git.feature.impl;

import 'package:devops/src/project_operations/git_feature.dart';
import 'package:devops/src/git/git.dart';
import 'package:logging/logging.dart';
import 'package:devops/src/project/project.dart';
import 'package:devops/src/project_operations/project_command.dart';
import 'package:devops/src/project/dependency_graph.dart';
import 'dart:io';
import 'package:option/option.dart';

Logger _log = new Logger('devops.project.operations.git.feature.impl');

class GitFeatureCommandsFlowImpl implements GitFeatureCommands {
  ProjectCommand init() => projectCommand('git flow init', (Project p) async {
    await initGitFlow(await p.gitDir);
  });

  ProjectCommand featureStart(String featureName) => projectCommand(
      'git flow feature start', (Project p) async {
    await gitFlowFeatureStart(await p.gitDir, featureName);
  });

  ProjectCommand featureFinish(String featureName) => projectCommand(
      'git flow feature finish', (Project p) async {
    await gitFlowFeatureFinish(await p.gitDir, featureName);
  });

  ProjectCommand releaseStart(String releaseName) => projectCommand(
      'git flow release start', (Project p) async {
    await gitFlowReleaseStart(await p.gitDir, releaseName);
  });

  ProjectCommand releaseFinish(String releaseName) => projectCommand(
      'git flow release finish', (Project p) async {
    var gitDir = await p.gitDir;
    await gitFlowReleaseFinish(gitDir, releaseName);
    await gitTag(gitDir, releaseName);
  });

  @override
  String get developBranchName => 'develop';

  ProjectDependencyGraphCommand currentFeatureName() => dependencyGraphCommand(
      'Get current feature name',
      (DependencyGraph graph, Directory rootDirectory) async {
    final featureNames = graph.depthFirst
        .map((pd) async =>
            await gitFlowCurrentFeatureName(await pd.project.gitDir))
        .where((o) => o is Some)
        .map((o) => o.get())
        .toSet();

    if (featureNames.length == 0) {
      return const None();
    } else if (featureNames.length == 1) {
      return new Some(featureNames.first);
    } else {
      throw new StateError('more than one current feature $featureNames');
    }
  });
}
