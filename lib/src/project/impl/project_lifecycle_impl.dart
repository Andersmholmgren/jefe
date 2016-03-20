// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.lifecycle.impl;

import 'dart:async';

import 'package:git/git.dart';
import 'package:jefe/src/project/impl/multi_project_command_support.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project/project_lifecycle.dart';
import 'package:jefe/src/project/pubspec_commands.dart';
import 'package:jefe/src/project/release_type.dart';
import 'package:jefe/src/project_commands/project_command.dart'
    show CommandConcurrencyMode, executeTask;
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:quiver/check.dart';

Logger _log = new Logger('jefe.project.commands.git.feature.impl');

const String featureStartCommitPrefix = 'set up project for new feature';

ProjectLifecycle createProjectLifecycle(JefeProjectGraph graph,
    {bool multiProject: true,
    CommandConcurrencyMode defaultConcurrencyMode,
    ProjectFilter projectFilter}) {
  return multiProject
      ? new ProjectLifecycleMultiProjectImpl(graph,
          defaultConcurrencyMode: defaultConcurrencyMode,
          projectFilter: projectFilter)
      : new ProjectLifecycleSingleProjectImpl(graph as JefeProject);
}

class ProjectLifecycleSingleProjectImpl
    extends SingleProjectCommandSupport<ProjectLifecycle>
    implements ProjectLifecycle {
  ProjectLifecycleSingleProjectImpl(JefeProject project)
      : super(
            (JefeProject p) async =>
                new _ProjectLifecycleSingleProjectImpl(project),
            project);
}

class ProjectLifecycleMultiProjectImpl
    extends MultiProjectCommandSupport<ProjectLifecycle>
    implements ProjectLifecycle {
  ProjectLifecycleMultiProjectImpl(JefeProjectGraph graph,
      {CommandConcurrencyMode defaultConcurrencyMode,
      ProjectFilter projectFilter})
      : super(graph,
            (JefeProject p) async => new ProjectLifecycleSingleProjectImpl(p),
            defaultConcurrencyMode: defaultConcurrencyMode,
            projectFilter: projectFilter);

  @override
  Future completeFeature({String featureName, bool doPush: false}) {
    return executeTask('complete development of feature $featureName',
        () async {
      await graph.git.assertWorkingTreeClean();
      return process(
          'complete feature',
          (JefeProject p) async => p.singleProjectCommands.lifecycle
              .completeFeature(featureName: featureName, doPush: doPush),
          mode: CommandConcurrencyMode.serialDepthFirst);
    });
  }

  @override
  Future release(
          {ReleaseType type: ReleaseType.minor,
          bool autoUpdateHostedVersions: false}) =>
      process(
          'release',
          (JefeProject p) async => p.singleProjectCommands.lifecycle.release(
              type: type, autoUpdateHostedVersions: autoUpdateHostedVersions),
          mode: CommandConcurrencyMode.serialDepthFirst);
}

class _ProjectLifecycleSingleProjectImpl implements ProjectLifecycle {
  final JefeProject _project;

  ProjectCommands get spc => _project.singleProjectCommands;

  _ProjectLifecycleSingleProjectImpl(this._project);

  @override
  Future startNewFeature(String featureName, {bool doPush: false}) async {
    await spc.git.assertWorkingTreeClean();
    await spc.gitFeature.featureStart(featureName);
    await spc.pubspecCommands.setToPathDependencies();
    await spc.pub.get();
    await spc.git.commit('$featureStartCommitPrefix $featureName');
    if (doPush) await spc.git.push();
  }

  @override
  Future completeFeature({String featureName, bool doPush: false}) async {
    if (await spc.gitFeature.isOnDevelopBranch) {
      _log.finer(
          'project ${_project.name} is already on develop branch. Nothing to do');
      return;
    }

    final currentFeatureNameOpt = await spc.gitFeature.currentFeatureName();
    if (currentFeatureNameOpt is Some &&
        featureName != null &&
        currentFeatureNameOpt.get() != featureName) {
      throw new StateError(
          'project ${_project.name} is on a different feature branch '
          '(${currentFeatureNameOpt.get()}) to that specified ($featureName');
    } else {
      final finishingFeatureName = featureName ?? currentFeatureNameOpt.get();

      checkState(finishingFeatureName != null,
          message: 'oops ended up with a null featureName somehow');

      if ((await spc.gitFeature.currentFeatureName()).getOrElse(() => null) !=
          finishingFeatureName) {
        throw new StateError(
            "project ${_project.name} is neither on feature branch or develop");
      }

      await spc.gitFeature.featureFinish(finishingFeatureName,
          excludeOnlyCommitIf: (Commit c) =>
              c.message.startsWith(featureStartCommitPrefix));

      await spc.pubspecCommands.setToGitDependencies();
      await spc.pub.get();
      await spc.git
          .commit('completed development of feature $finishingFeatureName');

      if (doPush) await spc.git.push();
    }
  }

  @override
  Future preRelease(
      {ReleaseType type: ReleaseType.minor,
      bool autoUpdateHostedVersions: false}) async {
    final _developBranchName = await spc.gitFeature.developBranchName;
    await spc.git.assertWorkingTreeClean();
    await spc.gitFeature.assertNoActiveReleases();
    await spc.git.assertOnBranch(_developBranchName);
    await spc.git.fetch();
    await spc.git.updateFromRemote('master');
    await spc.git.updateFromRemote(_developBranchName);
    await spc.git.merge('master');
    await checkReleaseVersions(
        type: type, autoUpdateHostedVersions: autoUpdateHostedVersions);
    await spc.pub.test();
  }

  Future checkReleaseVersions(
          {ReleaseType type: ReleaseType.minor,
          bool autoUpdateHostedVersions: false}) =>
      executeTask('check release versions', () async {
        final ProjectVersions versions =
            await getCurrentProjectVersions(type, autoUpdateHostedVersions);
        if (versions.newReleaseVersion is Some) {
          _log.info(
              '==> project ${_project.name} will be upgraded from version: '
              '${versions.taggedGitVersion} '
              'to: ${versions.newReleaseVersion.get()}. '
              'It will ${versions.hasBeenPublished ? "" : "NOT "}be published to pub');
        } else {
          _log.info('project ${_project.name} will NOT be upgraded. '
              'It will remain at version: ${versions.pubspecVersion}');
        }
      });

  @override
  Future release(
      {ReleaseType type: ReleaseType.minor,
      bool autoUpdateHostedVersions: false,
      bool recursive: true}) async {
    final ProjectVersions projectVersions =
        await getCurrentProjectVersions(type, autoUpdateHostedVersions);

    if (!projectVersions.newReleaseRequired) {
      // no release needed
      _log.fine('no changes needing release for ${_project.name}');
      return;
    } else {
      final releaseVersion = projectVersions.newReleaseVersion.get();

      _log.fine('new release version $releaseVersion');

      await spc.gitFeature.releaseStart(releaseVersion.toString());

      if (releaseVersion != projectVersions.pubspecVersion) {
        await _project
            .updatePubspec(_project.pubspec.copy(version: releaseVersion));
      }

      await spc.pubspecCommands.setToHostedDependencies();

      await spc.pub.get();

      await spc.pub.test();

      await spc.git.commit('releasing version $releaseVersion');

      if (projectVersions.currentVersions.isHosted) {
        await spc.pub.publish();
      }

      await spc.gitFeature.releaseFinish(releaseVersion.toString());

      await spc.git.push();
    }
  }

  @override
  Future init({bool doCheckout: true}) async {
    await spc.git.fetch();
    await spc.gitFeature.init();

    final currentFeatureNameOpt = await spc.gitFeature.currentFeatureName();

    if (currentFeatureNameOpt is Some) {
      final currentFeatureName = currentFeatureNameOpt.get();
      _log.info('Detected existing feature - $currentFeatureName');
      await startNewFeature(currentFeatureName);
    } else {
      if (doCheckout)
        await spc.git.checkout(await spc.gitFeature.developBranchName);
    }
  }

  Future<ProjectVersions> getCurrentProjectVersions(
      ReleaseType type, bool autoUpdateHostedVersions) async {
    final currentProjectVersions = await _project.projectVersions;

    _log.fine('${_project.name}: $currentProjectVersions');

    final Option<Version> releaseVersionOpt = await _getReleaseVersion(
        currentProjectVersions, autoUpdateHostedVersions, type);

    return new ProjectVersions(currentProjectVersions, releaseVersionOpt);
  }

  Future<Option<Version>> _getReleaseVersion(ProjectVersions2 currentVersions,
      bool autoUpdateHostedVersions, ReleaseType type) async {
    final hasBeenPublished = currentVersions.hasBeenPublished;
    final isHosted = currentVersions.isHosted;
    final currentPubspecVersion = currentVersions.pubspecVersion;

    if (currentVersions.hasBeenGitTagged) {
      final latestTaggedVersion = currentVersions.taggedGitVersion.get();
      if (latestTaggedVersion > currentPubspecVersion) {
        throw new StateError('the latest tagged version $latestTaggedVersion'
            ' is greater than the current pubspec version $currentPubspecVersion');
      } else if (latestTaggedVersion < currentPubspecVersion) {
        // manually bumped version
        return new Some<Version>(currentPubspecVersion);
      } else {
        // latest released version is same as pubspec version
        if (await hasChanges) {
          if (isHosted && !autoUpdateHostedVersions) {
            // Hosted packages must observe semantic versioning so not sensible
            // to try to automatically bump version, unless the user explicitly
            // requests it
            throw new ArgumentError(
                '${_project.name} is hosted and has changes. '
                'The version must be manually changed for hosted packages');
          } else {
            return new Some(type.bump(currentPubspecVersion));
          }
        } else {
          return const None();
        }
      }
    } else {
      // never been tagged
      if (hasBeenPublished) {
        if (currentPubspecVersion > currentVersions.publishedVersion.get()) {
          return new Some(currentPubspecVersion);
        } else {
          _log.warning(() =>
              "Project ${_project.name} is hosted but has never been tagged in git. "
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

  Future<bool> get hasChanges async =>
      new Stream<bool>.fromFutures(<Future<bool>>[
        spc.gitFeature.hasChangesSinceLatestTaggedVersion,
        spc.pubspecCommands.haveDependenciesChanged(DependencyType.hosted)
      ]).any((b) => b);
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
