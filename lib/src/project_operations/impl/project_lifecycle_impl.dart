library devops.project.operations.lifecycle.impl;

import 'dart:async';
import 'package:devops/src/project_operations/git_feature.dart';
import 'package:devops/src/project_operations/impl/core.dart';
import 'package:logging/logging.dart';
import 'package:devops/src/project.dart';
import 'package:devops/src/project_operations/project_lifecycle.dart';
import 'package:devops/src/project_operations/project_command.dart';
import 'package:devops/src/project_operations/git_commands.dart';

Logger _log = new Logger('devops.project.operations.git.feature.impl');

class ProjectLifecycleImpl /*extends BaseCommand*/ implements ProjectLifecycle {
  final GitFeatureCommands _gitFeature;
  final GitCommands _git;

  ProjectLifecycleImpl(ProjectSource projectSource,
      {GitFeatureCommandsFactory gitFeatureFactory: defaultFlowFeatureFactory})
      : this._gitFeature = gitFeatureFactory();
//      ,
//        super(projectSource);

  // TODO: Would be nice if this is just a command too.
  // Maybe it is a ProjectCommandList or something

  CompositeProjectCommand startNewFeature2(String featureName,
      {bool doPush: false, bool recursive: true}) {
    return projectCommandGroup('d', [
      _gitFeature.featureStart(featureName),
      _pubSpec.setToPathDependencies(),
      _git.commit('set path dependencies for start of feature $featureName'),
      _git.push(),
      _pub.get()
    ]);
  }

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
  CompositeProjectCommand completeFeature2(String featureName,
      {bool doPush: false, bool recursive: true}) {
    return projectCommandGroup('d', [
      _gitFeature.featureFinish(featureName),
      _pubSpec.setToGitDependencies(), // This must be serial
      _git.commit('set git dependencies for end of feature $featureName'),
      _git.push(),
      _pub.get()
    ]);

//    final newVersion = type.bump(pubspec.version);
//    await releaseStart(newVersion.toString());
//    await updatePubspec(pubspec.copy(version: newVersion));
//    await setToGitDependencies(dependencies);
//    await commit('releasing version $newVersion');
//    await releaseFinish(newVersion.toString());
//    await push();

  }

  @override
  Future release(Iterable<Project> dependencies,
      {ReleaseType type: ReleaseType.minor}) {
    // TODO: implement release
  }
}
