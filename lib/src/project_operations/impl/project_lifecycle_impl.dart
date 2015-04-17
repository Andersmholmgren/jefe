library devops.project.operations.lifecycle.impl;

import 'dart:async';
import 'package:devops/src/project_operations/git_feature.dart';
import 'package:devops/src/project_operations/impl/core.dart';
import 'package:logging/logging.dart';
import 'package:devops/src/project.dart';
import 'package:devops/src/project_operations/project_lifecycle.dart';
import 'package:devops/src/project_operations/project_command.dart';
import 'package:devops/src/project_operations/git_commands.dart';
import 'package:devops/src/project_operations/pub_commands.dart';
import 'package:devops/src/project_operations/pubspec_commands.dart';

Logger _log = new Logger('devops.project.operations.git.feature.impl');

class ProjectLifecycleImpl /*extends BaseCommand*/ implements ProjectLifecycle {
  final GitFeatureCommands _gitFeature;
  final GitCommands _git;
  final PubCommands _pub;
  final PubSpecCommands _pubSpec;

  ProjectLifecycleImpl(
      {GitFeatureCommandsFactory gitFeatureFactory: defaultFlowFeatureFactory})
      : this._gitFeature = gitFeatureFactory(),
        this._git = new GitCommands(),
        this._pub = new PubCommands(),
        this._pubSpec = new PubSpecCommands();
//      ,
//        super(projectSource);

  // TODO: Would be nice if this is just a command too.
  // Maybe it is a ProjectCommandList or something

  @override
  CompositeProjectCommand startNewFeature(String featureName,
      {bool doPush: false, bool recursive: true}) {
    return projectCommandGroup('set up project for new feature "$featureName"',
        [
      _gitFeature.featureStart(featureName),
      _pubSpec.setToPathDependencies(),
      _git.commit('set path dependencies for start of feature $featureName'),
      _git.push(),
      _pub.get()
    ]);
  }

  @override
//  Future startNewFeature(String featureName,
//      {bool doPush: false, bool recursive: true}) async {
//    await _gitFeature.featureStart(featureName);
//    await _pubSpec.setToPathDependencies();
//    await _git
//        .commit('set path dependencies for start of feature $featureName');
//    if (doPush) {
//      await _git.push();
//    }
//    await _pub.get();
////    });
//  }

  @override
  CompositeProjectCommand completeFeature(String featureName,
      {bool doPush: false, bool recursive: true}) {
    return projectCommandGroup('close off feature $featureName', [
      _gitFeature.featureFinish(featureName),
      _pubSpec.setToGitDependencies(), // This must be serial
      _git.commit('set git dependencies for end of feature $featureName'),
      _git.push(),
      _pub.get()
    ]);

//    final newVersion = type.bump(pubspec.version);
//    await releaseStart(newVersion.toString());
//    await updatePubspec(pubspec.copy(version: newVersion));
////    await setToGitDependencies(dependencies);
//    await commit('releasing version $newVersion');
//    await releaseFinish(newVersion.toString());
//    await push();

  }

  @override
  CompositeProjectCommand release({ReleaseType type: ReleaseType.minor}) {
    return projectCommandGroup('Release version type $type', [
      _gitFeature.releaseStart(newVersion.toString()),
      _pubSpec.updateVersion(newVersion),
      _git.commit('releasing version $newVersion'),
      _gitFeature.releaseFinish(newVersion.toString()),
      _git.push()
    ]);
  }

  @override
  ProjectCommand<ProjectWithDependenciesFunction> release2(
      {ReleaseType type: ReleaseType.minor}) {
    return projectCommand('Release version type $type',
        (Project project) async {
      final newVersion = type.bump(project.pubspec.version);
      await _gitFeature.releaseStart(newVersion.toString()).function(project);
      await _pubSpec
          .updatePubspec(project.pubspec.copy(version: newVersion))
          .function(project);
      //    await setToGitDependencies(dependencies);
      await _git.commit('releasing version $newVersion').function(project);
      await _gitFeature.releaseFinish(newVersion.toString()).function(project);
      await _git.push().function(project);
    });
//    [
//      _gitFeature.releaseStart(newVersion.toString()),
//      _pubSpec.updateVersion(newVersion),
//      _git.commit('releasing version $newVersion'),
//      _gitFeature.releaseFinish(newVersion.toString()),
//      _git.push()
//    ]);
  }
}

//typedef Future ProjectCommandExecutorXX(ProjectCommand command);
