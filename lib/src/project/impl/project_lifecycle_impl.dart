// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.lifecycle.impl;

import 'dart:async';

import 'package:git/git.dart';
import 'package:jefe/src/git/git.dart';
import 'package:jefe/src/project/git_commands.dart';
import 'package:jefe/src/project/git_feature.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project/project_lifecycle.dart';
import 'package:jefe/src/project/pub_commands.dart';
import 'package:jefe/src/project/pubspec_commands.dart';
import 'package:jefe/src/project/release_type.dart';
import 'package:jefe/src/project_commands/project_command.dart'
    show executeTask;
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:pub_semver/pub_semver.dart';

Logger _log = new Logger('jefe.project.commands.git.feature.impl');

const String featureStartCommitPrefix = 'set up project for new feature';

class ProjectLifecycleImpl implements ProjectLifecycle {
  final JefeProjectGraph _graph;
  ProjectLifecycleImpl(this._graph);

  GitCommands get _git => _graph.git;
  GitFeatureCommands get _gitFeature => _graph.gitFeature;
  PubCommands get _pub => _graph.pub;
  PubSpecCommands get _pubspec => _graph.pubspecCommands;

  @override
  Future startNewFeature(String featureName,
      {bool doPush: false, bool recursive: true}) {
    if (!recursive)
      return startNewFeatureForCurrentProject(featureName, doPush: doPush);

    return executeTask(
        'set up project for new feature $featureName',
        () => _graph.processDepthFirst((JefeProject project) => project
            .lifecycle
            .startNewFeature(featureName, doPush: doPush, recursive: false)));
  }

  Future startNewFeatureForCurrentProject(String featureName,
      {bool doPush: false}) {
    return executeTask(
        'set up project for new feature "$featureName" for project ${_graph.name}',
        () async {
      await _git.assertWorkingTreeClean();
      await _gitFeature.featureStart(featureName);
      await _pubspec.setToPathDependencies();
      await _pub.get();
      await _git.commit('$featureStartCommitPrefix $featureName');
      if (doPush) await _git.push();
    });
  }

  @override
  Future completeFeature(String featureName,
      {bool doPush: false, bool recursive: true}) {
    if (!recursive)
      return completeFeatureForCurrentProject(featureName, doPush: doPush);

    Future doComplete(JefeProject project) => project.lifecycle
        .completeFeature(featureName, doPush: doPush, recursive: false);

    return executeTask('complete development of feature $featureName',
        () => _graph.processDepthFirst(doComplete));
  }

  Future completeFeatureForCurrentProject(String featureName,
      {bool doPush: false}) {
    return executeTask(
        'complete development of feature $featureName for project ${_graph.name}',
        () async {
      await _git.assertWorkingTreeClean();

      final currentBranchName =
          await gitCurrentBranchName(await _graph.gitDir);
      if (!(currentBranchName == _gitFeature.developBranchName)) {
        await _gitFeature.featureFinish(featureName,
            excludeOnlyCommitIf: (Commit c) =>
                c.message.startsWith(featureStartCommitPrefix));
      }

      await _pubspec.setToGitDependencies();
      await _pub.get();
      await _git.commit('completed development of feature $featureName');

      if (doPush) await _git.push();
    });
  }

  @override
  Future preRelease(
      {ReleaseType type: ReleaseType.minor,
      bool autoUpdateHostedVersions: false,
      bool recursive: true}) {
    if (!recursive)
      return preReleaseCurrentProject(type, autoUpdateHostedVersions);

    Future doPreRelease(JefeProject project) => project.lifecycle.preRelease(
        type: type,
        autoUpdateHostedVersions: autoUpdateHostedVersions,
        recursive: false);

    return executeTask('Pre release checks: type $type',
        () => _graph.processDepthFirst(doPreRelease));
  }

  Future preReleaseCurrentProject(
          ReleaseType type, bool autoUpdateHostedVersions) =>
      executeTask('Pre release checks for project ${_graph.name}', () async {
        await _git.assertWorkingTreeClean();
        await _gitFeature.assertNoActiveReleases();
        await _git.assertOnBranch(_gitFeature.developBranchName);
        await _git.fetch();
        await _git.updateFromRemote('master');
        await _git.updateFromRemote(_gitFeature.developBranchName);
        await _git.merge('master');
        await checkReleaseVersions(
            type: type, autoUpdateHostedVersions: autoUpdateHostedVersions);
        await _pub.test();
      });

  Future checkReleaseVersions(
          {ReleaseType type: ReleaseType.minor,
          bool autoUpdateHostedVersions: false}) =>
      executeTask('check release versions', () async {
        final ProjectVersions versions = await getCurrentProjectVersions(
            _graph, type, autoUpdateHostedVersions);
        if (versions.newReleaseVersion is Some) {
          _log.info(
              '==> project ${_graph.name} will be upgraded from version: '
              '${versions.taggedGitVersion} '
              'to: ${versions.newReleaseVersion.get()}. '
              'It will ${versions.hasBeenPublished ? "" : "NOT "}be published to pub');
        } else {
          _log.info('project ${_graph.name} will NOT be upgraded. '
              'It will remain at version: ${versions.pubspecVersion}');
        }
      });

  @override
  Future release(
      {ReleaseType type: ReleaseType.minor,
      bool autoUpdateHostedVersions: false,
      bool recursive: true}) {
    if (!recursive)
      return releaseCurrentProject(type, autoUpdateHostedVersions);

    Future doRelease(JefeProject project) => project.lifecycle.release(
        type: type,
        autoUpdateHostedVersions: autoUpdateHostedVersions,
        recursive: false);

    return executeTask('Release version: type $type',
        () => _graph.processDepthFirst(doRelease));
  }

  Future releaseCurrentProject(
      ReleaseType type, bool autoUpdateHostedVersions) {
    return executeTask(
        'Release version: type $type for project ${_graph.name}', () async {
      final ProjectVersions projectVersions = await getCurrentProjectVersions(
          _graph, type, autoUpdateHostedVersions);

      if (!projectVersions.newReleaseRequired) {
        // no release needed
        _log.fine('no changes needing release for ${_graph.name}');
        return;
      } else {
        final releaseVersion = projectVersions.newReleaseVersion.get();

        _log.fine('new release version $releaseVersion');

        await _gitFeature.releaseStart(releaseVersion.toString());

        if (releaseVersion != projectVersions.pubspecVersion) {
          await _graph
              .updatePubspec(_graph.pubspec.copy(version: releaseVersion));
        }

        await _pubspec.setToHostedDependencies();

        await _pub.get();

        await _pub.test();

        await _git.commit('releasing version $releaseVersion');

        if (projectVersions.currentVersions.isHosted) {
          await _pub.publish();
        }

        await _gitFeature.releaseFinish(releaseVersion.toString());

        await _git.push();
      }
    });
  }

  @override
  Future init({bool doCheckout: true, bool recursive: true}) {
    if (!recursive) return initCurrentProject(doCheckout);

    Future doInit(JefeProject project) =>
        project.lifecycle.init(doCheckout: doCheckout, recursive: false);

    return executeTask('Initialising for development',
        () => _graph.processDepthFirst(doInit));
  }

  Future initCurrentProject(bool doCheckout) {
    return executeTask(
        'Initialising for development for project ${_graph.name}', () async {
      await _git.fetch();
      await _gitFeature.init();

      final currentFeatureNameOpt = await _gitFeature.currentFeatureName();

      if (currentFeatureNameOpt is Some) {
        final currentFeatureName = currentFeatureNameOpt.get();
        _log.info('Detected existing feature - $currentFeatureName');
        await startNewFeature(currentFeatureName);
      } else {
        if (doCheckout) await _git.checkout(_gitFeature.developBranchName);
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
                '${project.name} is hosted and has changes. '
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

  Future<bool> get hasChanges async =>
      new Stream<bool>.fromFutures(<Future<bool>>[
        _gitFeature.hasChangesSinceLatestTaggedVersion,
        _pubspec.haveDependenciesChanged(DependencyType.hosted)
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
