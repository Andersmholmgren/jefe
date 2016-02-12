// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.git.impl;

import 'package:jefe/src/git/git.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:logging/logging.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'dart:async';

Logger _log = new Logger('jefe.project.commands.git.impl');

abstract class GitCommandsImpl /*implements GitCommands */ {
//  Future<GitDir> get gitDir;

  final JefeProject _project;
  GitCommandsImpl(this._project);

  Future commit(String message) => executeTask('git commit',
      () async => await gitCommit(await _project.gitDir, message));

  ProjectCommand push() => projectCommand('git push', (Project p) async {
        await gitPush(await _project.gitDir);
      });

  ProjectCommand fetch() => projectCommand('git fetch', (Project p) async {
        await gitFetch(await _project.gitDir);
      });

  ProjectCommand assertWorkingTreeClean() =>
      projectCommand('git assertWorkingTreeClean', (Project p) async {
        if (!await (await _project.gitDir).isWorkingTreeClean()) {
          throw new StateError(
              'working directory dirty for project ${_project.name}');
        }
      });

  ProjectCommand assertOnBranch(String branchName) =>
      projectCommand('git assertOnBranch $branchName', (Project p) async {
        var currentBranchName =
            (await (await _project.gitDir).getCurrentBranch()).branchName;
        if (currentBranchName != branchName) {
          throw new StateError(
              '${_project.name} is on different branch ($currentBranchName) than '
              'expected ($branchName). Make sure you run jefe finish first');
        }
      });

  ProjectCommand checkout(String branchName) =>
      projectCommand('git checkout $branchName', (Project p) async {
        await gitCheckout(await _project.gitDir, branchName);
      });

  ProjectCommand updateFromRemote(String branchName,
          [String remoteName = 'origin']) =>
      projectCommand('git update from remote: $branchName', (Project p) async {
        final gitDir = await _project.gitDir;
        await gitCheckout(gitDir, branchName);
        await gitMerge(gitDir, '$remoteName/$branchName');
      });

  ProjectCommand merge(String commit) =>
      projectCommand('git merge $commit', (Project p) async {
        await gitMerge(await _project.gitDir, commit);
      });
}
