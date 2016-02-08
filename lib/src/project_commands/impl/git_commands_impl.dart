// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.git.impl;

import 'package:jefe/src/git/git.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project_commands/git_commands.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:logging/logging.dart';

Logger _log = new Logger('jefe.project.commands.git.impl');

class GitCommandsImpl implements GitCommands {
  @override
  ProjectCommand commit(String message) =>
      projectCommand('git commit', (Project p) async {
        await gitCommit(await p.gitDir, message);
      });

  @override
  ProjectCommand push() => projectCommand('git push', (Project p) async {
        await gitPush(await p.gitDir);
      });

  @override
  ProjectCommand fetch() => projectCommand('git fetch', (Project p) async {
        await gitFetch(await p.gitDir);
      });

  @override
  ProjectCommand assertWorkingTreeClean() =>
      projectCommand('git assertWorkingTreeClean', (Project p) async {
        if (!await (await p.gitDir).isWorkingTreeClean()) {
          throw new StateError('working directory dirty for project ${p.name}');
        }
      });

  @override
  ProjectCommand assertOnBranch(String branchName) =>
      projectCommand('git assertOnBranch $branchName', (Project p) async {
        var currentBranchName =
            (await (await p.gitDir).getCurrentBranch()).branchName;
        if (currentBranchName != branchName) {
          throw new StateError(
              '${p.name} is on different branch ($currentBranchName) than '
              'expected ($branchName). Make sure you run jefe finish first');
        }
      });

  @override
  ProjectCommand checkout(String branchName) =>
      projectCommand('git checkout $branchName', (Project p) async {
        await gitCheckout(await p.gitDir, branchName);
      });

  @override
  ProjectCommand updateFromRemote(String branchName,
          [String remoteName = 'origin']) =>
      projectCommand('git update from remote: $branchName', (Project p) async {
        final gitDir = await p.gitDir;
        await gitCheckout(gitDir, branchName);
        await gitMerge(gitDir, '$remoteName/$branchName');
      });

  @override
  ProjectCommand merge(String commit) =>
      projectCommand('git merge $commit', (Project p) async {
        await gitMerge(await p.gitDir, commit);
      });
}
