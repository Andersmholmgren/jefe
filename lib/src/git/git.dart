// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.git;

import 'package:git/git.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';
import 'package:option/option.dart';

Logger _log = new Logger('jefe.git');

Future<GitDir> gitWorkspaceDir(String gitUri, Directory parentDirectory) =>
    GitDir.fromExisting(gitWorkspacePath(gitUri, parentDirectory));

String gitWorkspaceName(String gitUri) => p.basenameWithoutExtension(gitUri);

String gitWorkspacePath(String gitUri, Directory parentDirectory) {
  return p.join(parentDirectory.path, gitWorkspaceName(gitUri));
}

enum OnExistsAction { pull, ignore }

Future<GitDir> cloneOrPull(String gitUri, Directory containerDirectory,
    Directory groupDirectory, OnExistsAction onExistsAction) async {

//  _log.fine(
//      'checking if $gitDirPath is a git workspace - git repo: $gitUri; parent directory $parentDirectory');
  if (await groupDirectory.exists() &&
      await GitDir.isGitDir(groupDirectory.path)) {
    if (onExistsAction == OnExistsAction.pull) {
      return pull(gitUri, groupDirectory);
    } else {
      return GitDir.fromExisting(groupDirectory.path);
    }
  } else {
    return clone(gitUri, containerDirectory);
  }
}

Future<GitDir> clone(String gitUri, Directory parentDirectory) async {
  _log.info('cloning git repo $gitUri into parent directory $parentDirectory');
  await runGit(['clone', gitUri.toString()],
      processWorkingDir: parentDirectory.path);

  _log.finest(
      'successfully cloned git repo $gitUri into parent directory $parentDirectory');

  return gitWorkspaceDir(gitUri, parentDirectory);
}

Future<GitDir> pull(String gitUri, Directory gitDirectory) async {
  _log.info('running git pull from repo $gitUri in directory $gitDirectory');
  final GitDir gitDir = await GitDir.fromExisting(gitDirectory.path);
//?  await gitDir.runCommand(['branch', '--set-upstream-to=origin/<branch> <branch>']);
  await gitDir.runCommand(['pull']);
//  await runGit(['pull'], processWorkingDir: gitDirectory.path);
  _log.finest(
      'successfully pulled git repo $gitUri into parent directory $gitDirectory');

  return await GitDir.fromExisting(gitDirectory.path);
}

Future gitCommit(GitDir gitDir, String message) async {
  if (!(await gitDir.isWorkingTreeClean())) {
    return gitDir.runCommand(['commit', '-am', message]);
  }
}

Future gitCheckout(GitDir gitDir, String branchName) async =>
    await gitDir.runCommand(['checkout', branchName]);

Future gitTag(GitDir gitDir, String tag) async =>
    await gitDir.runCommand(['tag', tag]);

Future gitPush(GitDir gitDir) async {
  final BranchReference current = await gitDir.getCurrentBranch();

  // TODO: make pushing tags optional
  await gitDir.runCommand(
      ['push', '--tags', '--set-upstream', 'origin', current.branchName]);
}

Future<String> currentCommitHash(GitDir gitDir) async =>
    (await gitDir.runCommand(['rev-parse', 'HEAD'])).stdout.trim();

// TODO: should generalise into fetching all remotes if any etc
Future<String> getFirstRemote(GitDir gitDir) async {
  final ProcessResult result = await gitDir.runCommand(['remote', '-v']);

  final String remotesStr = result.stdout;

  final firstLine = remotesStr.split('\n').first;

  return firstLine.split(new RegExp(r'\s+')).elementAt(1);
}

Future initGitFlow(GitDir gitDir) async =>
    await gitDir.runCommand(['flow', 'init', '-d']);

Future gitFlowFeatureStart(GitDir gitDir, String featureName) async =>
    await gitDir.runCommand(['flow', 'feature', 'start', featureName]);

Future gitFlowFeatureFinish(GitDir gitDir, String featureName) async =>
    await gitDir.runCommand(['flow', 'feature', 'finish', featureName]);

Future gitFlowReleaseStart(GitDir gitDir, String version) async =>
    await gitDir.runCommand(['flow', 'release', 'start', version]);

Future gitFlowReleaseFinish(GitDir gitDir, String version) async => await gitDir
    .runCommand([
  'flow',
  'release',
  'finish',
//  '-m',
//  '"released version $version"',
  '-n',
  version
]);

Future<Option<String>> gitFlowCurrentFeatureName(GitDir gitDir) async {
  final String branchName = (await gitDir.getCurrentBranch()).branchName;
  if (branchName.startsWith('feature/')) {
    return new Some(branchName.replaceFirst('feature/', ''));
  } else {
    return const None();
  }
}

Future<Option<String>> gitCurrentTagName(GitDir gitDir) async => new Option(
    (await gitDir.runCommand(['describe', 'HEAD', '--tags'])).stdout.trim());
