// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.git.impl;

import 'dart:async';

import 'package:jefe/src/git/git.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:logging/logging.dart';

Logger _log = new Logger('jefe.project.commands.git.impl');

abstract class GitCommandsImpl /*implements GitCommands */ {
//  Future<GitDir> get gitDir;

  final JefeProject _project;
  GitCommandsImpl(this._project);

  Future commit(String message) => executeTask(
      'git commit', () async => gitCommit(await _project.gitDir, message));

  Future push() =>
      executeTask('git push', () async => gitPush(await _project.gitDir));

  Future fetch() => executeTask('git fetch', () async {
        await gitFetch(await _project.gitDir);
      });

  Future assertWorkingTreeClean() =>
      executeTask('git assertWorkingTreeClean', () async {
        if (!await (await _project.gitDir).isWorkingTreeClean()) {
          throw new StateError(
              'working directory dirty for project ${_project.name}');
        }
      });

  Future assertOnBranch(String branchName) =>
      executeTask('git assertOnBranch $branchName', () async {
        var currentBranchName =
            (await (await _project.gitDir).getCurrentBranch()).branchName;
        if (currentBranchName != branchName) {
          throw new StateError(
              '${_project.name} is on different branch ($currentBranchName) than '
              'expected ($branchName). Make sure you run jefe finish first');
        }
      });

  Future checkout(String branchName) =>
      executeTask('git checkout $branchName', () async {
        await gitCheckout(await _project.gitDir, branchName);
      });

  Future updateFromRemote(String branchName, [String remoteName = 'origin']) =>
      executeTask('git update from remote: $branchName', () async {
        final gitDir = await _project.gitDir;
        await gitCheckout(gitDir, branchName);
        await gitMerge(gitDir, '$remoteName/$branchName');
      });

  Future merge(String commit) => executeTask('git merge $commit', () async {
        await gitMerge(await _project.gitDir, commit);
      });
}
