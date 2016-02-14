// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.git.impl;

import 'dart:async';

import 'package:jefe/src/git/git.dart';
import 'package:jefe/src/project/git_commands.dart';
import 'package:jefe/src/project/impl/BaseCommandsImpl.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:git/git.dart';

Logger _log = new Logger('jefe.project.commands.git.impl');

class GitCommandsImpl extends BaseCommandsImpl<GitCommands> implements GitCommands {
  GitCommandsImpl(JefeProjectGraph graph) : super(graph,
    (JefeProject p) async => new _GitCommandsImpl(p, await p.gitDir));

//  Future<_GitCommandsImpl> _single(JefeProject p) async =>
//    new _GitCommandsImpl(p, await p.gitDir);
//
//  typedef Future/*<T>*/ X/*<T>*/(_GitCommandsImpl single);

  Future com(String message) => single((GitCommands s) => s.commit(message));

  @override
  Future commit(String message) => processAllConcurrently('git commit',
      (JefeProject p) async => await _single(p).commit(message));

  @override
  Future push() => processAllConcurrently(
      'git push', (JefeProject p) async => gitPush(await p.gitDir));

  @override
  Future fetch() => executeTask('git fetch', (JefeProject p) async {
        await gitFetch(await p.gitDir);
      });

  @override
  Future assertWorkingTreeClean() =>
      executeTask('git assertWorkingTreeClean', (JefeProject p) async {
        if (!await (await p.gitDir).isWorkingTreeClean()) {
          throw new StateError(
              'working directory dirty for project ${graph.name}');
        }
      });

  @override
  Future assertOnBranch(String branchName) =>
      executeTask('git assertOnBranch $branchName', (JefeProject p) async {
        var currentBranchName =
            (await (await p.gitDir).getCurrentBranch()).branchName;
        if (currentBranchName != branchName) {
          throw new StateError(
              '${graph.name} is on different branch ($currentBranchName) than '
              'expected ($branchName). Make sure you run jefe finish first');
        }
      });

  @override
  Future checkout(String branchName) =>
      executeTask('git checkout $branchName', (JefeProject p) async {
        await gitCheckout(await p.gitDir, branchName);
      });

  @override
  Future updateFromRemote(String branchName, [String remoteName = 'origin']) =>
      executeTask('git update from remote: $branchName', (JefeProject p) async {
        final gitDir = await p.gitDir;
        await gitCheckout(gitDir, branchName);
        await gitMerge(gitDir, '$remoteName/$branchName');
      });

  @override
  Future merge(String commit) =>
      executeTask('git merge $commit', (JefeProject p) async {
        await gitMerge(await p.gitDir, commit);
      });

  @override
  Future<bool> hasChangesSince(Version sinceVersion) async {
    return (await diffSummarySince(await p.gitDir, sinceVersion.toString()))
        is Some;
  }
}


class _GitCommandsImpl implements GitCommands {
  final JefeProject _project;
  final GitDir _gitDir;

  _GitCommandsImpl(this._project, this._gitDir);

//  Future<GitDir> get _gitDir => _graph.gitDir;

  @override
  Future commit(String message) => gitCommit(_gitDir, message);

  @override
  Future push() => gitPush(_gitDir);

  @override
  Future fetch() => executeTask('git fetch', (JefeProject p) async {
    await gitFetch(await p.gitDir);
  });

  @override
  Future assertWorkingTreeClean() =>
    executeTask('git assertWorkingTreeClean', (JefeProject p) async {
      if (!await (await p.gitDir).isWorkingTreeClean()) {
        throw new StateError(
          'working directory dirty for project ${graph.name}');
      }
    });

  @override
  Future assertOnBranch(String branchName) =>
    executeTask('git assertOnBranch $branchName', (JefeProject p) async {
      var currentBranchName =
        (await (await p.gitDir).getCurrentBranch()).branchName;
      if (currentBranchName != branchName) {
        throw new StateError(
          '${graph.name} is on different branch ($currentBranchName) than '
            'expected ($branchName). Make sure you run jefe finish first');
      }
    });

  @override
  Future checkout(String branchName) =>
    executeTask('git checkout $branchName', (JefeProject p) async {
      await gitCheckout(await p.gitDir, branchName);
    });

  @override
  Future updateFromRemote(String branchName, [String remoteName = 'origin']) =>
    executeTask('git update from remote: $branchName', (JefeProject p) async {
      final gitDir = await p.gitDir;
      await gitCheckout(gitDir, branchName);
      await gitMerge(gitDir, '$remoteName/$branchName');
    });

  @override
  Future merge(String commit) =>
    executeTask('git merge $commit', (JefeProject p) async {
      await gitMerge(await p.gitDir, commit);
    });

  @override
  Future<bool> hasChangesSince(Version sinceVersion) async {
    return (await diffSummarySince(await p.gitDir, sinceVersion.toString()))
    is Some;
  }
}
