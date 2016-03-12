// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.git.impl;

import 'dart:async';
import 'dart:mirrors';

import 'package:git/git.dart';
import 'package:jefe/src/git/git.dart';
import 'package:jefe/src/project/git_commands.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:jefe/src/project/impl/multi_project_command_support.dart';

Logger _log = new Logger('jefe.project.commands.git.impl');

class GitCommandsMultiProjectImpl extends MultiProjectCommandSupport<GitCommands>
    implements GitCommands {
  GitCommandsMultiProjectImpl(GitCommands single, JefeProject project)
      : super(
            single,
            project,
            (JefeProject p) async =>
                new GitCommandsSingleProjectImpl(p, await p.gitDir));
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
