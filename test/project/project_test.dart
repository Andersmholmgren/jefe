library devops.project.test;

import 'package:devops/src/project.dart';
import 'dart:io';
import 'package:devops/src/git.dart';
import 'package:path/path.dart' as p;
import 'package:git/git.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';
import 'package:devops/src/yaml/yaml_writer.dart';
import 'package:devops/src/pubspec/pubspec_model.dart';
import 'dart:async';

mainB() async {
  final ProjectGroupMetaData metadata = await ProjectGroupMetaData
      .fromProjectGroupYamlFile(p.absolute('project.yaml'));

  print(metadata.name);
  print(metadata.childGroups);
}

mainA() async {
  final Directory installDir = await Directory.systemTemp.createTemp();

  print(installDir);

  print((await Process.run('ls', ['-l', installDir.path])).stdout);

//  final url = Uri.parse(
//      'https://andersmholmgren@bitbucket.org/andersmholmgren/shelf_path.git');

//  print(p.basenameWithoutExtension(url.path));
  final GitDir gitDir = await clone(
      'https://andersmholmgren@bitbucket.org/andersmholmgren/shelf_path.git',
      installDir);

  print(await gitDir.isWorkingTreeClean());

  final Directory installDir2 = await Directory.systemTemp.createTemp();
  print(installDir2);

  final GitDir gitDir2 =
      await clone(p.join(installDir.path, 'shelf_path'), installDir2);
}

//main() async {
//  getRemotes(await GitDir.fromExisting('/Users/blah/dart/shelf/shelf_route'));
//}

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(print);
  hierarchicalLoggingEnabled = true;

  ProjectGroupRef ref = new ProjectGroupRef.fromGitUrl(
      'top', '/Users/blah/dart/jefe_jefe/jefe_test_projects/gitbacklog');

  final Directory installDir = await Directory.systemTemp.createTemp();

  print(installDir);

  final ProjectGroup projectGroup = await ref.install(installDir);

//  await projectGroup.install(installDir);
//  await projectGroup.setupForDev();

  final ProjectGroup projectGroup2 =
      await ProjectGroup.fromInstallDirectory(projectGroup.installDirectory);
  print(projectGroup2.gitUri);
  print(projectGroup2.installDirectory);
  print(projectGroup2.metaData);

  await projectGroup2.initFlow();
//  await projectGroup2.featureStart('blah');

  await projectGroup2.setupForNewFeature('awesomeness');

//  await new Future.delayed(const Duration(minutes: 2));

//  await projectGroup2.featureFinish('awesomeness');

//  await projectGroup2.release();
}

//mainVV() async {
//  var pubspecPath = '/Users/blah/dart/backlogio/gissue/gissue_client';
//  print(pubspecPath);
//  final Pubspec pubspec = await Pubspec.load(pubspecPath);
////  pubspec.name = 'something much longer than the original';
//  print(pubspec.contents);
//  print(pubspec.dependencies);
////  pubspec.addDependency(new PackageDep('quiver', 'path', null, '../quiver'));
////  pubspec.addDependency(new PackageDep('ah_polymer_stuff', 'path', null, '../ah_polymer_stuff'));
//  pubspec.addDependency(new PackageDep('quiver', 'git', null, 'quiver'));
//
//  print(pubspec.dependencies);
//  print(pubspec.contents);
//}

mainxxxx() async {
  var pubspecPath =
      '/Users/blah/dart/backlogio/gissue/gissue_client/pubspec.yaml';
  print(pubspecPath);
//  final Pubspec pubspec = await Pubspec.load(pubspecPath);
  var pubspecStr = await new File(pubspecPath).readAsString();
  print(pubspecStr);
  final YamlDocument doc = loadYamlDocument(pubspecStr);
  print(doc.toString());
//  print(toYamlString(doc.contents));
  writeYamlString(doc.contents, stdout);
}

mainbbbb() async {
  var pubspecParentPath = '/Users/blah/dart/backlogio/gissue/gissue_client';
  var pubspecPath = '$pubspecParentPath/pubspec.yaml';
  print(pubspecPath);
//  final Pubspec pubspec = await Pubspec.load(pubspecPath);
  var pubspecStr = await new File(pubspecPath).readAsString();
  print(pubspecStr);

  final pubspec = await PubSpec.load(new Directory(pubspecParentPath));
  print(pubspec.toJson());
  writeYamlString(pubspec.toJson(), stdout);
}
