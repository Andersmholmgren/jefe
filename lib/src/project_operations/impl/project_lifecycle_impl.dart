library devops.project.operations.lifecycle.impl;

import 'dart:async';
import 'package:devops/src/project_operations/git_feature.dart';
import 'package:devops/src/project_operations/impl/core.dart';
import 'package:logging/logging.dart';
import 'package:devops/src/project.dart';
import 'package:devops/src/project_operations/project_lifecycle.dart';

Logger _log = new Logger('devops.project.operations.git.feature.impl');

class ProjectLifecycleImpl /*extends BaseCommand*/ implements ProjectLifecycle {
  final GitFeatureCommands _gitFeature;

  ProjectLifecycleImpl(ProjectSource projectSource,
      {GitFeatureCommandsFactory gitFeatureFactory: defaultFlowFeatureFactory})
      : this._gitFeature = gitFeatureFactory(projectSource);
//      ,
//        super(projectSource);

  @override
  Future startNewFeature(String featureName,
      {bool doPush: false, bool recursive: true}) async {
    await _gitFeature.featureStart(featureName);
    await _pubSpec.setToPathDependencies();
    await _git
        .commit('set path dependencies for start of feature $featureName');
    if (doPush) {
      await _git.push();
    }
    await _pub.get();
//    });
  }

  @override
  Future completeFeature(String featureName,
      {bool doPush: false, bool recursive: true}) {
    // TODO: implement completeFeature
  }

  @override
  Future release(Iterable<Project> dependencies,
      {ReleaseType type: ReleaseType.minor}) {
    // TODO: implement release
  }
}
