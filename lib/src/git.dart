library devops.git;

import 'package:git/git.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

String gitWorkspaceName(Uri gitUri) => p.basenameWithoutExtension(gitUri.path);

String gitWorkspacePath(Uri gitUri, Directory parentDirectory) =>
    p.join(parentDirectory.path, gitWorkspaceName(gitUri));

Future<GitDir> clone(Uri gitUri, Directory parentDirectory) async {
  final ProcessResult result = await runGit(['clone', gitUri.toString()],
      processWorkingDir: parentDirectory.path);

  print(result.stdout);

  return GitDir.fromExisting(gitWorkspacePath(gitUri, parentDirectory));
}
