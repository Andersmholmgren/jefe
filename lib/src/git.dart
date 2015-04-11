library devops.git;

import 'package:git/git.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

Future<GitDir> gitWorkspaceDir(Uri gitUri, Directory parentDirectory) =>
    GitDir.fromExisting(gitWorkspacePath(gitUri, parentDirectory));

String gitWorkspaceName(Uri gitUri) => p.basenameWithoutExtension(gitUri.path);

String gitWorkspacePath(Uri gitUri, Directory parentDirectory) {
  print('---- $gitUri ---- $parentDirectory');
  return p.join(parentDirectory.path, gitWorkspaceName(gitUri));
}

Future<GitDir> clone(Uri gitUri, Directory parentDirectory) async {
  final ProcessResult result = await runGit(['clone', gitUri.toString()],
      processWorkingDir: parentDirectory.path);

  print(result.stdout);

  return gitWorkspaceDir(gitUri, parentDirectory);
}

// TODO: should generalise into fetching all remotes if any etc
Future<Uri> getFirstRemote(GitDir gitDir) async {
  final ProcessResult result = await gitDir.runCommand(['remote', '-v']);

  final String remotesStr = result.stdout;
//  print(remotesStr);

  final firstLine = remotesStr.split('\n').first;
//  print(firstLine);
//  print(firstLine.split(new RegExp(r'\s+')));

  return Uri.parse(firstLine.split(new RegExp(r'\s+')).elementAt(1));
}

Future initGitFlow(GitDir gitDir) async =>
    await gitDir.runCommand(['flow', 'init', '-d']);
