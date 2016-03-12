// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.git.feature.impl;

import 'dart:async';

import 'package:git/git.dart';
import 'package:jefe/src/git/git.dart';
import 'package:jefe/src/project/git_feature.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project_commands/project_command.dart'
    show ProjectDependencyGraphCommand, dependencyGraphCommand, executeTask;
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:jefe/src/project/impl/multi_project_command_support.dart';

Logger _log = new Logger('jefe.project.commands.git.feature.impl');

abstract class GitFeatureCommandsFlowImpl implements GitFeatureCommands {
  factory GitFeatureCommandsFlowImpl(JefeProject project, {bool multiProject: true}) {
    return multiProject
      ? new GitFeatureCommandsMultiProjectFlowImpl(project)
      : new GitFeatureCommandsSingleProjectFlowImpl(project);
  }
}

class GitFeatureCommandsSingleProjectFlowImpl
  extends SingleProjectCommandSupport<GitFeatureCommands> implements GitFeatureCommands {
  GitFeatureCommandsSingleProjectFlowImpl(JefeProject project)
    : super(
    (JefeProject p) async =>
  new _GitFeatureCommandsSingleProjectFlowImpl(project, await p.gitDir),
    project);
}


class GitFeatureCommandsMultiProjectFlowImpl
  extends MultiProjectCommandSupport<GitFeatureCommands> implements GitFeatureCommands {

  GitFeatureCommandsMultiProjectFlowImpl(JefeProjectGraph graph);
    : super(graph, (JefeProject p) async => new GitFeatureCommandsSingleProjectFlowImpl(p));

  @override
  String get developBranchName => 'develop';

  @override
  Future<Option<String>> currentFeatureName() {
    /*
    Damn this is a case where the multi project needs to reduce the results from
    the singles
     */

    Future<Option<String>> featureNameFor() async {
      final featureNames =
          await new Stream<JefeProject>.fromIterable(_graph.depthFirst)
              .asyncMap(
                  (p) async => await gitFlowCurrentFeatureName(await p.gitDir))
              .where((o) => o is Some)
              .map((o) => o.get())
              .toSet();

      if (featureNames.length == 0) {
        return const None();
      } else if (featureNames.length == 1) {
        return new Some<String>(featureNames.first);
      } else {
        throw new StateError('more than one current feature $featureNames');
      }
    }

    return executeTask/*<Option<String>>*/(
        'Get current feature name', featureNameFor);
  }

  @override
  Future<Iterable<Version>> getReleaseVersionTags() {
    Future<Iterable<Version>> fetchTags() async {
      final gitDir = await _graph.gitDir;
      return await gitFetchVersionTags(gitDir);
    }
    return executeTask('fetch git release version tags', fetchTags);
  }

  @override
  Future assertNoActiveReleases() =>
      executeTask('check no active releases', () async {
        final releaseNames = await gitFlowReleaseNames(await _graph.gitDir);
        if (releaseNames.isNotEmpty) {
          throw new StateError(
              '${_graph.name} has an existing release branch. Must finish all active releases first');
        }
      });

  Future<FeatureNames> fetchCurrentProjectsFeatureNames() async {
    final gitDir = await _graph.gitDir;
    final results = await Future
        .wait([gitFlowFeatureNames(gitDir), gitFlowCurrentFeatureName(gitDir)]);

    return new FeatureNames(
        (results[0] as Iterable<String>).toSet(), results[1] as Option<String>);
  }

  @override
  Future<bool> get hasChangesSinceLatestTaggedVersion async =>
      (await _graph.latestTaggedGitVersion)
          .map((v) => _graph.git.hasChangesSince(v))
          .getOrElse(() => false);
}

class _GitFeatureCommandsSingleProjectFlowImpl implements GitFeatureCommands {
  final JefeProject _project;
  final GitDir _gitDir;

  _GitFeatureCommandsSingleProjectFlowImpl(this._project, this._gitDir);

  Future init() => executeTask('git flow init', () async {
        await initGitFlow(_gitDir);
      });

  Future featureStart(String featureName, {bool throwIfExists: false}) async {
    final featureNames = await fetchCurrentProjectsFeatureNames();
    if (featureNames.featureExists(featureName)) {
      if (throwIfExists)
        throw new StateError("Feature '$featureName' already exists");
      else if (featureNames.currentFeatureIs(featureName)) {
        // correct feature
        // TODO: could check the branch is correctly based off develop
        _log.info('${_project.name} already on correct feature branch');
      } else {
        return gitCheckout(_gitDir, '$featureBranchPrefix$featureName');
      }
    } else {
      return gitFlowFeatureStart(_gitDir, featureName);
    }
  }

  Future featureFinish(String featureName,
      {bool excludeOnlyCommitIf(Commit commit): _dontExclude}) async {
    final GitDir gitDir = _gitDir;
    final Map<String, Commit> commits =
        await gitDir.getCommits('$developBranchName..HEAD');
    _log.info('found ${commits.length} commits on feature branch');
    if (commits.length == 1 && excludeOnlyCommitIf(commits.values.first)) {
      // TODO: we should really delete the feature branch but a bit paranoid
      // doing that for now
      _log.info('feature branch only contains original autogenerated commit.'
          ' Not merging changes');
      await gitCheckout(gitDir, developBranchName);
    } else {
      await gitFlowFeatureFinish(gitDir, featureName);
    }
  }

  Future releaseStart(String releaseName) async =>
      gitFlowReleaseStart(_gitDir, releaseName);

  Future releaseFinish(String releaseName) async {
    var gitDir = _gitDir;
    await gitFlowReleaseFinish(gitDir, releaseName);
    await gitTag(gitDir, releaseName);
    await gitPush(gitDir);
    await gitCheckout(gitDir, developBranchName);
    await gitMerge(gitDir, 'master', ffOnly: false);
    await gitDir.runCommand(['push', 'origin', 'master']);
  }

  @override
  String get developBranchName => 'develop';

  @override
  Future<Option<String>> currentFeatureName() async {
    final featureNames = await new Stream<JefeProject>.fromIterable(
            _project.depthFirst)
        .asyncMap((p) async => await gitFlowCurrentFeatureName(await p.gitDir))
        .where((o) => o is Some)
        .map((o) => o.get())
        .toSet();

    if (featureNames.length == 0) {
      return const None();
    } else if (featureNames.length == 1) {
      return new Some<String>(featureNames.first);
    } else {
      throw new StateError('more than one current feature $featureNames');
    }
  }

  @override
  Future<Iterable<Version>> getReleaseVersionTags() async =>
      gitFetchVersionTags(_gitDir);

  @override
  Future assertNoActiveReleases() async {
    final releaseNames = await gitFlowReleaseNames(_gitDir);
    if (releaseNames.isNotEmpty) {
      throw new StateError(
          '${_project.name} has an existing release branch. Must finish all active releases first');
    }
  }

  Future<FeatureNames> fetchCurrentProjectsFeatureNames() async {
    final results = await Future.wait(
        [gitFlowFeatureNames(_gitDir), gitFlowCurrentFeatureName(_gitDir)]);

    return new FeatureNames(
        (results[0] as Iterable<String>).toSet(), results[1] as Option<String>);
  }

  @override
  Future<bool> get hasChangesSinceLatestTaggedVersion async =>
      (await _project.latestTaggedGitVersion)
          .map((v) => _project.git.hasChangesSince(v))
          .getOrElse(() => false);
}

bool _dontExclude(Commit c) => false;

class FeatureNames {
  final Set<String> featureNames;
  final Option<String> currentFeatureName;

  FeatureNames(this.featureNames, this.currentFeatureName);

  bool currentFeatureIs(String featureName) =>
      currentFeatureName is Some && currentFeatureName.get() == featureName;

  bool featureExists(String featureName) => featureNames.contains(featureName);
}
