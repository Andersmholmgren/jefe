library devops.project.test;

import 'package:devops/src/project.dart';
import 'dart:io';
import 'package:devops/src/git.dart';
import 'package:path/path.dart' as p;
import 'dart:async';
import 'package:git/git.dart';

main() async {
  final Directory installDir = await Directory.systemTemp.createTemp();

  print(installDir);

  print((await Process.run('ls', ['-l', installDir.path])).stdout);

//  final url = Uri.parse(
//      'https://andersmholmgren@bitbucket.org/andersmholmgren/shelf_path.git');

//  print(p.basenameWithoutExtension(url.path));
  final GitDir gitDir = await clone(Uri.parse(
          'https://andersmholmgren@bitbucket.org/andersmholmgren/shelf_path.git'),
      installDir);

  print(await gitDir.isWorkingTreeClean());
}

mainX() async {
  ProjectRef ref = new ProjectRef.fromGitUrl(Uri.parse(''));

  final Project project = await ref.fetch();

  final Directory installDir = await Directory.systemTemp.createTemp();

  print(installDir);
  await project.install(installDir);
  await project.setupForDev();
}
