// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.git;

import 'package:git/git.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:pub_semver/pub_semver.dart';

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

Future gitCheckout(GitDir gitDir, String branchName) async {
  await gitDir.runCommand(['checkout', branchName]);
  await gitDir..runCommand(['branch', '-u', 'origin/$branchName']);
  await gitDir..runCommand(['merge', 'origin/$branchName']);
}

Future gitTag(GitDir gitDir, String tag) async =>
    await gitDir.runCommand(['tag', '-a', '-m', 'release $tag', tag]);

Future<Iterable<Version>> gitFetchVersionTags(GitDir gitDir) async =>
    (await gitDir.getTags()).map((Tag tag) {
  try {
    return new Some(new Version.parse(tag.tag));
  } on FormatException catch (_) {
    return const None();
  }
}).where((o) => o is Some).map((o) => o.get()).toList()..sort();

Future gitPush(GitDir gitDir) async {
  final BranchReference current = await gitDir.getCurrentBranch();

  // TODO: make pushing tags optional
  await gitDir.runCommand(
      ['push', '--tags', '--set-upstream', 'origin', current.branchName]);
}

Future gitFetch(GitDir gitDir) async {
  await gitDir.runCommand(['fetch', '--tags']);
}

Future gitMerge(GitDir gitDir, String commit) async {
  await gitDir.runCommand(['merge', '--ff-only', commit]);
}

Future<String> currentCommitHash(GitDir gitDir) async =>
    (await gitDir.runCommand(['rev-parse', 'HEAD'])).stdout.trim();

Future<String> getOriginOrFirstRemote(GitDir gitDir) async {
  final remotes = await getRemotes(gitDir);
  return remotes.firstWhere((r) => r.name == 'origin',
      orElse: () => remotes.first).uri;
}

Future<Iterable<GitRemote>> getRemotes(GitDir gitDir) async {
  final ProcessResult result = await gitDir.runCommand(['remote', '-v']);

  final String remotesStr = result.stdout;

  final lines = remotesStr.split('\n');

  return lines.map((l) => l.split(new RegExp(r'\s+'))).map(
      (Iterable<String> kv) => new GitRemote(kv.elementAt(0), kv.elementAt(1)));
}

Future<int> commitCountSince(GitDir gitDir, String ref) async =>
    await gitDir.getCommitCount('$ref..HEAD');

Future<Option<DiffSummary>> diffSummarySince(GitDir gitDir, String ref) async {
  final line = (await gitDir.runCommand(['diff', '--shortstat', ref])).stdout;
  return line != null && line.trim().isNotEmpty
      ? new Some(new DiffSummary.parse(line))
      : const None();
}

class DiffSummary {
//  static final RegExp _diffRegExp = new RegExp(
//      r'^\s*(\d+) file[s]? changed, (\d+) insertions\(\+\), (\d+) deletions\(\-\)\s*$');

  static final RegExp _filesRegExp = new RegExp(r'\s*(\d+) file[s]? changed.*');
  static final RegExp _insertionsRegExp = new RegExp(r'.*, (\d+) insertion.*');
  static final RegExp _deletionsRegExp = new RegExp(r'.*, (\d+) deletion.*');

  final int filesChangedCount;
  final int insertionCount;
  final int deletionCount;

  DiffSummary(this.filesChangedCount, this.insertionCount, this.deletionCount);

  factory DiffSummary.parse(String line) {
    int value(RegExp regExp) {
      final match = regExp.firstMatch(line);
      return match != null ? int.parse(match.group(1)) : 0;
    }

    return new DiffSummary(
        value(_filesRegExp), value(_insertionsRegExp), value(_deletionsRegExp));
  }

  String toString() =>
      '$filesChangedCount files changed, $insertionCount insertions(+), '
      '$deletionCount deletions(-)';
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

Future<String> gitCurrentBranchName(GitDir gitDir) async =>
    (await gitDir.getCurrentBranch()).branchName;

Future<Option<String>> gitFlowCurrentFeatureName(GitDir gitDir) async {
  final branchName = await gitCurrentBranchName(gitDir);
  if (branchName.startsWith(featureBranchPrefix)) {
    return new Some(branchName.replaceFirst(featureBranchPrefix, ''));
  } else {
    return const None();
  }
}

Future<Iterable<String>> gitFlowFeatureNames(GitDir gitDir) async =>
    _gitFlowBranchNames(gitDir, featureBranchPrefix);

Future<Iterable<String>> gitFlowReleaseNames(GitDir gitDir) async =>
    _gitFlowBranchNames(gitDir, releaseBranchPrefix);

Future<Iterable<String>> _gitFlowBranchNames(
    GitDir gitDir, String branchPrefix) async {
  final Iterable<String> branchNames = await gitDir.getBranchNames();
  return branchNames
      .where((n) => n.startsWith(branchPrefix))
      .map((n) => n.substring(branchPrefix.length));
}

Future<Option<String>> gitCurrentTagName(GitDir gitDir) async => new Option(
    (await gitDir.runCommand(['describe', 'HEAD', '--tags'])).stdout.trim());

const String featureBranchPrefix = 'feature/';
const String releaseBranchPrefix = 'release/';

class GitRemote {
  final String name;
  final String uri;

  GitRemote(this.name, this.uri);
}
