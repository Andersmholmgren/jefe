// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.git.impl;

import 'dart:async';

import 'package:jefe/src/git/git.dart';
import 'package:jefe/src/project/git_commands.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:pub_semver/pub_semver.dart';

Logger _log = new Logger('jefe.project.commands.git.impl');

class GitCommandsImpl implements GitCommands {
  final JefeProject _project;
  GitCommandsImpl(this._project);

  Future<GitDir> get _gitDir => _project.gitDir;

  @override
  Future commit(String message) =>
      executeTask('git commit', () async => gitCommit(await _gitDir, message));

  @override
  Future push() => executeTask('git push', () async => gitPush(await _gitDir));

  @override
  Future fetch() => executeTask('git fetch', () async {
        await gitFetch(await _gitDir);
      });

  @override
  Future assertWorkingTreeClean() =>
      executeTask('git assertWorkingTreeClean', () async {
        if (!await (await _gitDir).isWorkingTreeClean()) {
          throw new StateError(
              'working directory dirty for project ${_project.name}');
        }
      });

  @override
  Future assertOnBranch(String branchName) =>
      executeTask('git assertOnBranch $branchName', () async {
        var currentBranchName =
            (await (await _gitDir).getCurrentBranch()).branchName;
        if (currentBranchName != branchName) {
          throw new StateError(
              '${_project.name} is on different branch ($currentBranchName) than '
              'expected ($branchName). Make sure you run jefe finish first');
        }
      });

  @override
  Future checkout(String branchName) =>
      executeTask('git checkout $branchName', () async {
        await gitCheckout(await _gitDir, branchName);
      });

  @override
  Future updateFromRemote(String branchName, [String remoteName = 'origin']) =>
      executeTask('git update from remote: $branchName', () async {
        final gitDir = await _gitDir;
        await gitCheckout(gitDir, branchName);
        await gitMerge(gitDir, '$remoteName/$branchName');
      });

  @override
  Future merge(String commit) => executeTask('git merge $commit', () async {
        await gitMerge(await _gitDir, commit);
      });

  @override
  Future<bool> hasChangesSince(Version sinceVersion) async {
    return (await diffSummarySince(await _gitDir, sinceVersion.toString()))
        is Some;
  }
}
