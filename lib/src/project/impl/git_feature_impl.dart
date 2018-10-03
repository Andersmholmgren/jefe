// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.git.feature.impl;

import 'dart:async';

import 'package:git/git.dart';
import 'package:jefe/src/git/git.dart';
import 'package:jefe/src/project/git_feature.dart';
import 'package:jefe/src/project/impl/multi_project_command_support.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:logging/logging.dart';
import 'package:quiver/core.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:quiver/check.dart';

Logger _log = new Logger('jefe.project.commands.git.feature.impl');

GitFeatureCommands createGitFeatureCommands(JefeProjectGraph graph,
    {bool multiProject: true,
    CommandConcurrencyMode defaultConcurrencyMode,
    ProjectFilter projectFilter}) {
  return multiProject
      ? new GitFeatureCommandsMultiProjectFlowImpl(graph,
          defaultConcurrencyMode: defaultConcurrencyMode,
          projectFilter: projectFilter)
      : new GitFeatureCommandsSingleProjectFlowImpl(graph as JefeProject);
}

class GitFeatureCommandsSingleProjectFlowImpl
    extends SingleProjectCommandSupport<GitFeatureCommands>
    implements GitFeatureCommands {
  GitFeatureCommandsSingleProjectFlowImpl(JefeProject project)
      : super(
            (JefeProject p) async =>
                new _GitFeatureCommandsSingleProjectFlowImpl(
                    project, await p.gitDir),
            project);

  @override
  Future assertNoActiveReleases() => doExecuteTask(
      'assertNoActiveReleases', (c) => c.assertNoActiveReleases());

  @override
  Future<Optional<String>> currentFeatureName() =>
      doExecuteTask('currentFeatureName', (c) => c.currentFeatureName());

  @override
  Future<String> get developBranchName =>
      doExecuteTask('developBranchName', (c) => c.developBranchName);

  @override
  Future featureFinish(String featureName,
          {bool Function(Commit commit) excludeOnlyCommitIf}) =>
      doExecuteTask(
          'featureFinish',
          (c) => c.featureFinish(featureName,
              excludeOnlyCommitIf: excludeOnlyCommitIf));

  @override
  Future featureStart(String featureName, {bool throwIfExists: false}) =>
      doExecuteTask('featureStart',
          (c) => c.featureStart(featureName, throwIfExists: throwIfExists));

  @override
  Future<Iterable<Version>> getReleaseVersionTags() =>
      doExecuteTask('getReleaseVersionTags', (c) => c.getReleaseVersionTags());

  @override
  Future<bool> get hasChangesSinceLatestTaggedVersion => doExecuteTask(
      'hasChangesSinceLatestTaggedVersion',
      (c) => c.hasChangesSinceLatestTaggedVersion);

  @override
  Future init() => doExecuteTask('init', (c) => c.init());

  @override
  Future<bool> get isOnDevelopBranch =>
      doExecuteTask('isOnDevelopBranch', (c) => c.isOnDevelopBranch);

  @override
  Future releaseFinish(String version) =>
      doExecuteTask('releaseFinish', (c) => c.releaseFinish(version));

  @override
  Future releaseStart(String version) =>
      doExecuteTask('releaseStart', (c) => c.releaseStart(version));
}

class GitFeatureCommandsMultiProjectFlowImpl
    extends MultiProjectCommandSupport<GitFeatureCommands>
    implements GitFeatureCommands {
  GitFeatureCommandsMultiProjectFlowImpl(JefeProjectGraph graph,
      {CommandConcurrencyMode defaultConcurrencyMode,
      ProjectFilter projectFilter})
      : super(
            graph,
            (JefeProject p) async =>
                new GitFeatureCommandsSingleProjectFlowImpl(p),
            defaultConcurrencyMode: defaultConcurrencyMode,
            projectFilter: projectFilter);

  @override
  Future<String> get developBranchName async => 'develop';

  @override
  Future<Optional<String>> currentFeatureName() async {
    Optional<String> extractName(
        Optional<String> previous, Optional<String> current) {
      if (previous.runtimeType != current.runtimeType ||
          (previous.orNull != current.orNull)) {
        throw new StateError(
            'found more than one feature name $previous and $current');
      }
      return current;
    }

    return process<Optional<String>>(
        'current feature name',
        (JefeProject p) async =>
            (await singleProjectCommandFactory(p)).currentFeatureName(),
        combine: extractName);
  }
}

class _GitFeatureCommandsSingleProjectFlowImpl implements GitFeatureCommands {
  final JefeProject _project;
  final GitDir _gitDir;

  ProjectCommands get spc => _project.singleProjectCommands;

  _GitFeatureCommandsSingleProjectFlowImpl(this._project, this._gitDir);

  Future init() => initGitFlow(_gitDir);

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
    checkArgument(featureName != null, message: 'featureName must be provided');
    final GitDir gitDir = _gitDir;
    final _developBranchName = await developBranchName;
    final Map<String, Commit> commits =
        await gitDir.getCommits('$_developBranchName..HEAD');
    _log.info('found ${commits.length} commits on feature branch $featureName');
    if (commits.length == 1 && excludeOnlyCommitIf(commits.values.first)) {
      // TODO: we should really delete the feature branch but a bit paranoid
      // doing that for now
      _log.info('feature branch only contains original autogenerated commit.'
          ' Not merging changes');
      await gitCheckout(gitDir, _developBranchName);
    } else {
      await gitFlowFeatureFinish(gitDir, featureName);
    }
  }

  Future releaseStart(String releaseName) async =>
      gitFlowReleaseStart(_gitDir, releaseName);

  Future releaseFinish(String releaseName) async {
    await gitFlowReleaseFinish(_gitDir, releaseName);
    await gitTag(_gitDir, releaseName);
    await gitPush(_gitDir);
    await gitCheckout(_gitDir, await developBranchName);
    await gitMerge(_gitDir, 'master', ffOnly: false);
    await _gitDir.runCommand(['push', 'origin', 'master']);
  }

  @override
  Future<String> get developBranchName async => 'develop';

  @override
  Future<Optional<String>> currentFeatureName() =>
      gitFlowCurrentFeatureName(_gitDir);

  @override
  Future<Iterable<Version>> getReleaseVersionTags() async =>
      gitFetchVersionTags(_gitDir);

  @override
  Future assertNoActiveReleases() async {
    final releaseNames = await gitFlowReleaseNames(_gitDir);
    if (releaseNames.isNotEmpty) {
      throw new StateError('${_project.name} has an existing release branch. '
          'Must finish all active releases first');
    }
  }

  // TODO: this is a single project command that doesn't make a lot of sense
  // to run on more than one project. Currently it is not in the interface for
  // that reason. We could implemented it by merging all the results if that is
  // useful??
  Future<FeatureNames> fetchCurrentProjectsFeatureNames() async {
    final results = await Future.wait(
        [gitFlowFeatureNames(_gitDir), gitFlowCurrentFeatureName(_gitDir)]);

    return new FeatureNames(results[0].toSet(), results[1] as Optional<String>);
  }

  @override
  Future<bool> get hasChangesSinceLatestTaggedVersion async {
    final latestTaggedGitVersion = await _project.latestTaggedGitVersion;
    final x = await (latestTaggedGitVersion
        .transform((v) => spc.git.hasChangesSince(v)));
    return x.or(Future.value(false));
  }

  @override
  Future<bool> get isOnDevelopBranch async =>
      (await _gitDir.getCurrentBranch()).branchName == await developBranchName;
}

bool _dontExclude(Commit c) => false;

class FeatureNames {
  final Set<String> featureNames;
  final Optional<String> currentFeatureName;

  FeatureNames(this.featureNames, this.currentFeatureName);

  bool currentFeatureIs(String featureName) =>
      currentFeatureName.isPresent && currentFeatureName.value == featureName;

  bool featureExists(String featureName) => featureNames.contains(featureName);
}
