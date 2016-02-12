// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.lifecycle.impl;

import 'dart:async';

import 'package:git/git.dart';
import 'package:jefe/src/git/git.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project/release_type.dart';
import 'package:jefe/src/project_commands/git_commands.dart';
import 'package:jefe/src/project_commands/git_feature.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:jefe/src/project_commands/project_command_executor.dart';
import 'package:jefe/src/project_commands/project_lifecycle.dart';
import 'package:jefe/src/project_commands/pub_commands.dart';
import 'package:jefe/src/project_commands/pubspec_commands.dart';
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:pub_semver/pub_semver.dart';

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
    return projectCommandGroup(
        'set up project for new feature "$featureName"', [
      _git.assertWorkingTreeClean(),
      _gitFeature.featureStart(featureName),
      _pubSpec.setToPathDependencies(),
      _pub.get(),
      _git.commit('$featureStartCommitPrefix $featureName'),
      _git.push().copy(condition: () => doPush)
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
        (JefeProject project) async {
      await project.git.assertWorkingTreeClean().process(project);

      final currentBranchName =
          await gitCurrentBranchName(await project.gitDir);
      if (!(currentBranchName == _gitFeature.developBranchName)) {
        await _gitFeature
            .featureFinish(featureName,
                excludeOnlyCommitIf: (Commit c) =>
                    c.message.startsWith(featureStartCommitPrefix))
            .process(project);
      }

      await _pubSpec.setToGitDependencies().process(project);
      await _pub.get().process(project);
      await _git
          .commit('completed development of feature $featureName')
          .process(project);
      await project.git.push().process(project);
    });
  }

  @override
  CompositeProjectCommand preRelease(
          {ReleaseType type: ReleaseType.minor,
          bool autoUpdateHostedVersions: false}) =>
      projectCommandGroup('Pre release checks', [
        _git.assertWorkingTreeClean(),
        _gitFeature.assertNoActiveReleases(),
        _git.assertOnBranch(_gitFeature.developBranchName),
        _git.fetch(),
        _git.updateFromRemote('master'),
        _git.updateFromRemote(_gitFeature.developBranchName),
        _git.merge('master'),
        checkReleaseVersions(
            type: type, autoUpdateHostedVersions: autoUpdateHostedVersions),
        _pub.test()
      ]);

  ProjectCommand checkReleaseVersions(
          {ReleaseType type: ReleaseType.minor,
          bool autoUpdateHostedVersions: false}) =>
      projectCommandWithDependencies('check release versions',
          (JefeProject project) async {
        final ProjectVersions versions = await getCurrentProjectVersions(
            project, type, autoUpdateHostedVersions);
        if (versions.newReleaseVersion is Some) {
          _log.info(
              '==> project ${project.name} will be upgraded from version: '
              '${versions.taggedGitVersion} '
              'to: ${versions.newReleaseVersion.get()}. '
              'It will ${versions.hasBeenPublished ? "" : "NOT "}be published to pub');
        } else {
          _log.info('project ${project.name} will NOT be upgraded. '
              'It will remain at version: ${versions.pubspecVersion}');
        }
      });

  @override
  ProjectCommand release(
      {ReleaseType type: ReleaseType.minor,
      bool autoUpdateHostedVersions: false}) {
    return projectCommandWithDependencies('Release version: type $type',
        (JefeProject project) async {
      final ProjectVersions projectVersions = await getCurrentProjectVersions(
          project, type, autoUpdateHostedVersions);

      if (!projectVersions.newReleaseRequired) {
        // no release needed
        _log.fine('no changes needing release for ${project.name}');
        return;
      } else {
        final releaseVersion = projectVersions.newReleaseVersion.get();

        _log.fine('new release version $releaseVersion');

        await _gitFeature
            .releaseStart(releaseVersion.toString())
            .process(project);

        if (releaseVersion != projectVersions.pubspecVersion) {
          await project
              .updatePubspec(project.pubspec.copy(version: releaseVersion));
        }

        await _pubSpec.setToHostedDependencies().process(project);

        await _pub.get().process(project);

        await _pub.test().process(project);

        await project.git.commit('releasing version $releaseVersion').process(project);

        if (projectVersions.hasBeenPublished) {
          await _pub.publish().process(project);
        }

        await _gitFeature
            .releaseFinish(releaseVersion.toString())
            .process(project);

        await project.git.push();
      }
    });
  }

  @override
  ExecutorAwareProjectCommand init({bool doCheckout: true}) {
    return executorAwareCommand('Initialising for development',
        (CommandExecutor executor) async {
      await executor.execute(projectCommandGroup(
          'Initialising for development', [_gitFeature.init(), project.git.fetch()]));

      final currentFeatureNameOpt =
          await executor.execute(_gitFeature.currentFeatureName());

      if (currentFeatureNameOpt is Some) {
        var currentFeatureName = currentFeatureNameOpt.get();
        _log.info('Detected existing feature - $currentFeatureName');
        await executor.execute(startNewFeature(currentFeatureName));
      } else {
        await executor.execute(_git
            .checkout(_gitFeature.developBranchName)
            .copy(condition: () => doCheckout));
      }
    });
  }

  Future<ProjectVersions> getCurrentProjectVersions(JefeProject project,
      ReleaseType type, bool autoUpdateHostedVersions) async {
    final currentProjectVersions = await project.projectVersions;

    _log.fine('${project.name}: $currentProjectVersions');

    final Option<Version> releaseVersionOpt = await _getReleaseVersion(
        currentProjectVersions, autoUpdateHostedVersions, type, project);

    return new ProjectVersions(currentProjectVersions, releaseVersionOpt);
  }

  Future<Option<Version>> _getReleaseVersion(
      ProjectVersions2 currentVersions,
      bool autoUpdateHostedVersions,
      ReleaseType type,
      JefeProject project) async {
    final hasBeenPublished = currentVersions.hasBeenPublished;
    final isHosted = currentVersions.isHosted;
    final currentPubspecVersion = currentVersions.pubspecVersion;

    if (currentVersions.hasBeenGitTagged) {
      final latestTaggedVersion = currentVersions.taggedGitVersion.get();
      if (latestTaggedVersion > currentPubspecVersion) {
        throw new StateError('the latest tagged version $latestTaggedVersion'
            ' is greater than the current pubspec version $currentPubspecVersion');
      } else {
        if (latestTaggedVersion < currentPubspecVersion) {
          // manually bumped version
          return new Some(currentPubspecVersion);
        } else {
          // latest released version is same as pubspec version
          final hasChangesSinceLatestTaggedVersion =
              await hasChangesSince(await project.gitDir, latestTaggedVersion);

          final hasChanges = hasChangesSinceLatestTaggedVersion ||
              (await _pubSpec
                  .haveDependenciesChanged(DependencyType.hosted)
                  .process(project));

          if (hasChanges) {
            if (isHosted && !autoUpdateHostedVersions) {
              // Hosted packages must observe semantic versioning so not sensible
              // to try to automatically bump version, unless the user explicitly
              // requests it
              throw new ArgumentError(
                  '${project.name} is hosted and has changes. '
                  'The version must be manually changed for hosted packages');
            } else {
              return new Some(type.bump(currentPubspecVersion));
            }
          } else {
            return const None();
          }
        }
      }
    } else {
      // never been tagged
      if (hasBeenPublished) {
        if (currentPubspecVersion > currentVersions.publishedVersion.get()) {
          return new Some(currentPubspecVersion);
        } else {
          _log.warning(() =>
              "Project ${project.name} is hosted but has never been tagged in git. "
              "Can't tell if there are unpublished changes. "
              "Will not release as pubspec version is not greater than hosted version");
          return const None();
        }
      } else {
        // never tagged and never published. Assume it needs releasing
        return new Some(currentPubspecVersion);
      }
    }
  }

//  Future<bool> _hasCommitsSince(GitDir gitDir, Version sinceVersion) async {
//    return (await commitCountSince(gitDir, sinceVersion.toString())) > 0;
//  }

}

class ProjectVersions {
  final ProjectVersions2 currentVersions;
  final Option<Version> newReleaseVersion;

  Version get pubspecVersion => currentVersions.pubspecVersion;
  Option<Version> get taggedGitVersion => currentVersions.taggedGitVersion;
  Option<Version> get publishedVersion => currentVersions.publishedVersion;

  bool get hasBeenPublished => publishedVersion is Some;
  bool get newReleaseRequired => newReleaseVersion is Some;

  ProjectVersions(this.currentVersions, this.newReleaseVersion);
}

main() {
  print(new Version(0, 0, 1) > new Version(0, 0, 1, build: '2'));
  print(new Version(0, 0, 1, build: '2') > new Version(0, 0, 1));
}
