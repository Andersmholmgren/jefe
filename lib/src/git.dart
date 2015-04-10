library devops.git;

import 'package:git/git.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

Future<GitDir> clone(Uri gitUri, Directory parentDirectory) async {
  final ProcessResult result = await runGit(['clone', gitUri.toString()],
      processWorkingDir: parentDirectory.path);

  print(result.stdout);

  final checkoutDirName = p.basenameWithoutExtension(gitUri.path);
  final checkoutDirPath = p.join(parentDirectory.path, checkoutDirName);
  return GitDir.fromExisting(checkoutDirPath);
}
