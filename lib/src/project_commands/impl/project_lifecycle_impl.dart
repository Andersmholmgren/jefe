// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.lifecycle.impl;

import 'dart:async';
import 'package:jefe/src/project_commands/git_feature.dart';
import 'package:logging/logging.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project_commands/project_lifecycle.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:jefe/src/project_commands/git_commands.dart';
import 'package:jefe/src/project_commands/pub_commands.dart';
import 'package:jefe/src/project_commands/pubspec_commands.dart';
import 'package:jefe/src/project/release_type.dart';
import 'package:git/git.dart';

Logger _log = new Logger('jefe.project.commands.git.feature.impl');

const String featureStartCommitPrefix = 'set up project for new feature';

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

  @override
  CompositeProjectCommand startNewFeature(String featureName,
      {bool doPush: false, bool recursive: true}) {
    return projectCommandGroup('set up project for new feature "$featureName"',
        [
      _gitFeature.featureStart(featureName),
      _pubSpec.setToPathDependencies(),
      _pub.get(),
      _git.commit('$featureStartCommitPrefix $featureName'),
      new OptionalPush(doPush, _git.push())
    ]);
  }

  // TODO: return to this approach once the concurrency support is implemented
  // to handle it
//  @override
//  CompositeProjectCommand completeFeature(String featureName,
//                                          {bool doPush: false, bool recursive: true}) {
//    return projectCommandGroup('close off feature $featureName', [
//      _gitFeature.featureFinish(featureName),
//      _pubSpec.setToGitDependencies(),
//      _git.commit('set git dependencies for end of feature $featureName'),
//      new OptionalPush(doPush, _git.push()),
//      _pub.get()
//    ]);
//  }

  @override
  ProjectCommand completeFeature(String featureName,
      {bool doPush: false, bool recursive: true}) {
    return projectCommandWithDependencies(
        'complete development of feature $featureName',
        (Project project, Iterable<Project> dependencies) async {
      await _gitFeature
          .featureFinish(featureName,
              excludeOnlyCommitIf: (Commit c) =>
                  c.message.startsWith(featureStartCommitPrefix))
          .process(project);
      await _pubSpec.setToGitDependencies().process(project,
          dependencies: dependencies);
      await _pub.get().process(project);
      await _git
          .commit('completed development of feature $featureName')
          .process(project);
      await _git.push().process(project);
    });
  }

  @override
  ProjectCommand release({ReleaseType type: ReleaseType.minor}) {
    return projectCommand('Release version type $type',
        (Project project) async {
      final newVersion = type.bump(project.pubspec.version);
      await _gitFeature.releaseStart(newVersion.toString()).process(project);
      await project.updatePubspec(project.pubspec.copy(version: newVersion));
      //    await setToGitDependencies(dependencies);
      await _git.commit('releasing version $newVersion').process(project);
      await _gitFeature.releaseFinish(newVersion.toString()).process(project);
      await _git.push().process(project);
    });
  }

  @override
  CompositeProjectCommand init() {
    return projectCommandGroup('Initialising for development', [
      _gitFeature.init(),
      _git.fetch(),
      _git.checkout(_gitFeature.developBranchName)
    ]);
  }
}

class OptionalPush implements ProjectCommand {
  final bool doPush;
  final ProjectCommand realPush;

  OptionalPush(this.doPush, this.realPush);

  @override
  CommandConcurrencyMode get concurrencyMode => realPush.concurrencyMode;

  // TODO: implement name
  @override
  String get name => '';

  @override
  Future process(Project project, {Iterable<Project> dependencies}) async {
    if (doPush) {
      await realPush.process(project, dependencies: dependencies);
    }
  }
}
