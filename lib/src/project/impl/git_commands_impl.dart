// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.git.impl;

import 'dart:async';

import 'package:git/git.dart';
import 'package:jefe/src/git/git.dart';
import 'package:jefe/src/project/git_commands.dart';
import 'package:jefe/src/project/impl/BaseCommandsImpl.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:pub_semver/pub_semver.dart';

Logger _log = new Logger('jefe.project.commands.git.impl');

class GitCommandsImpl extends BaseCommandsImpl<GitCommands>
    implements GitCommands {
  GitCommandsImpl(JefeProjectGraph graph)
      : super(
            graph,
            (JefeProject p) async =>
                new GitCommandsSingleProjectImpl(p, await p.gitDir));

  @override
  Future commit(String message) =>
      process('git commit', (GitCommands s) => s.commit(message));

  @override
  Future push() => process('git push', (GitCommands s) => s.push());

  @override
  Future fetch() => process('git fetch', (GitCommands s) => s.fetch());

  @override
  Future assertWorkingTreeClean() => process('git assertWorkingTreeClean',
      (GitCommands s) => s.assertWorkingTreeClean());

  @override
  Future assertOnBranch(String branchName) => process(
      'git assertOnBranch $branchName',
      (GitCommands s) => s.assertOnBranch(branchName));

  @override
  Future checkout(String branchName) => process(
      'git checkout $branchName', (GitCommands s) => s.checkout(branchName));

  @override
  Future updateFromRemote(String branchName, [String remoteName = 'origin']) =>
      process('git update from remote: $branchName',
          (GitCommands s) => s.updateFromRemote(branchName, remoteName));

  @override
  Future merge(String commitMessage) =>
      process('git merge', (GitCommands s) => s.merge(commitMessage));

  @override
  Future<bool> hasChangesSince(Version sinceVersion) => process(
      'git has changes since $sinceVersion',
      (GitCommands s) => s.hasChangesSince(sinceVersion));
}

class GitCommandsSingleProjectImpl implements GitCommands {
  final JefeProject _project;
  final GitDir _gitDir;

  GitCommandsSingleProjectImpl(this._project, this._gitDir);

  @override
  Future commit(String message) => gitCommit(_gitDir, message);

  @override
  Future push() => gitPush(_gitDir);

  @override
  Future fetch() => gitFetch(_gitDir);

  @override
  Future assertWorkingTreeClean() => _gitDir.isWorkingTreeClean();

  @override
  Future assertOnBranch(String branchName) async {
    var currentBranchName = (await (_gitDir).getCurrentBranch()).branchName;
    if (currentBranchName != branchName) {
      throw new StateError(
          '${_project.name} is on different branch ($currentBranchName) than '
          'expected ($branchName). Make sure you run jefe finish first');
    }
  }

  @override
  Future checkout(String branchName) => gitCheckout(_gitDir, branchName);

  @override
  Future updateFromRemote(String branchName,
      [String remoteName = 'origin']) async {
    await gitCheckout(_gitDir, branchName);
    await gitMerge(_gitDir, '$remoteName/$branchName');
  }

  @override
  Future merge(String commit) => gitMerge(_gitDir, commit);

  @override
  Future<bool> hasChangesSince(Version sinceVersion) async {
    return (await diffSummarySince(_gitDir, sinceVersion.toString())) is Some;
  }

  @override
  Future<GitCommands> singleProjectCommandFor(JefeProject project) async {
    if (project != _project) throw new ArgumentError.value('damn');

    return this;
  }
}
