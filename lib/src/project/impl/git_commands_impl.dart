// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.git.impl;

import 'dart:async';

import 'package:git/git.dart';
import 'package:jefe/src/git/git.dart';
import 'package:jefe/src/project/git_commands.dart';
import 'package:jefe/src/project/impl/multi_project_command_support.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:jefe/src/project_commands/project_command.dart';

Logger _log = new Logger('jefe.project.commands.git.impl');

GitCommands createGitCommands(JefeProjectGraph graph,
    {bool multiProject: true,
    CommandConcurrencyMode defaultConcurrencyMode,
    ProjectFilter projectFilter}) {
  return multiProject
      ? new GitCommandsMultiProjectImpl(graph,
          defaultConcurrencyMode: defaultConcurrencyMode,
          projectFilter: projectFilter)
      : new GitCommandsSingleProjectImpl(graph as JefeProject);
}

class GitCommandsSingleProjectImpl
    extends SingleProjectCommandSupport<GitCommands> implements GitCommands {
  GitCommandsSingleProjectImpl(JefeProject project)
      : super(
            (JefeProject p) async =>
                new _GitCommandsSingleProjectImpl(project, await p.gitDir),
            project);
}

class GitCommandsMultiProjectImpl
    extends MultiProjectCommandSupport<GitCommands> implements GitCommands {
  GitCommandsMultiProjectImpl(JefeProjectGraph graph,
      {CommandConcurrencyMode defaultConcurrencyMode,
      ProjectFilter projectFilter})
      : super(
            graph, (JefeProject p) async => new GitCommandsSingleProjectImpl(p),
            defaultConcurrencyMode: defaultConcurrencyMode,
            projectFilter: projectFilter);
}

class _GitCommandsSingleProjectImpl implements GitCommands {
  final JefeProject _project;
  final GitDir _gitDir;

  _GitCommandsSingleProjectImpl(this._project, this._gitDir);

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

  // TODO: remove this??
  @override
  Future<GitCommands> singleProjectCommandFor(JefeProject project) async {
    if (project != _project) throw new ArgumentError.value('damn');

    return this;
  }
}
