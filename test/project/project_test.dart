library devops.project.test;

import 'package:devops/src/project.dart';
import 'dart:io';
import 'package:devops/src/git.dart';
import 'package:path/path.dart' as p;
import 'dart:async';
import 'package:git/git.dart';
import 'package:logging/logging.dart';

mainB() async {
  final ProjectMetaData metadata =
      await ProjectMetaData.fromProjectYamlFile(p.absolute('project.yaml'));

  print(metadata.name);
  print(metadata.childProjects);
}

mainA() async {
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

  final Directory installDir2 = await Directory.systemTemp.createTemp();
  print(installDir2);

  final GitDir gitDir2 = await clone(
      Uri.parse(p.join(installDir.path, 'shelf_path')), installDir2);
}

//main() async {
//  getRemotes(await GitDir.fromExisting('/Users/blah/dart/shelf/shelf_route'));
//}

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(print);
  hierarchicalLoggingEnabled = true;

  ProjectRef ref = new ProjectRef.fromGitUrl(
      'top', Uri.parse('/Users/blah/dart/jefe_jefe/jefe_test_projects/top'));

  final Directory installDir = await Directory.systemTemp.createTemp();

  print(installDir);

  final Project project = await ref.install(installDir);

//  await project.install(installDir);
//  await project.setupForDev();

  final Project project2 =
      await Project.fromInstallDirectory(project.installDirectory);
  print(project2.gitUri);
  print(project2.installDirectory);
  print(project2.metaData);
}
