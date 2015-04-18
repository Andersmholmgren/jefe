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

class ProjectLifecycleImpl implements ProjectLifecycle {
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
  CompositeProjectCommand completeFeature(String featureName,
      {bool doPush: false, bool recursive: true}) {
    return projectCommandGroup('close off feature $featureName', [
      _gitFeature.featureFinish(featureName),
      _pubSpec.setToGitDependencies(), // This must be serial
      _git.commit('set git dependencies for end of feature $featureName'),
      _git.push(),
      _pub.get()
    ]);
  }

  @override
  ProjectCommand release({ReleaseType type: ReleaseType.minor}) {
    return projectCommand('Release version type $type',
        (Project project) async {
      final newVersion = type.bump(project.pubspec.version);
      await _gitFeature.releaseStart(newVersion.toString()).process(project);
      await _pubSpec
          .update(project.pubspec.copy(version: newVersion))
          .process(project);
      //    await setToGitDependencies(dependencies);
      await _git.commit('releasing version $newVersion').process(project);
      await _gitFeature.releaseFinish(newVersion.toString()).process(project);
      await _git.push().process(project);
    });
  }
}
