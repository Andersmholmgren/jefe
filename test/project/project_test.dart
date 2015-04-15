library devops.project.test;

import 'package:devops/src/project.dart';
import 'dart:io';
import 'package:devops/src/git.dart';
import 'package:path/path.dart' as p;
import 'package:git/git.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';
import 'package:devops/src/yaml/yaml_writer.dart';
import 'package:devops/src/pubspec/pubspec.dart';
import 'package:devops/src/spec/JefeSpec.dart' as spec;
import 'dart:async';
import 'package:stack_trace/stack_trace.dart';
import 'package:devops/src/project_impl.dart';
import 'package:devops/src/project_group_impl.dart';

mainB() async {
  final spec.ProjectGroupMetaData metadata = await spec.ProjectGroupMetaData
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

  Chain.capture(() {
    main123();
  }, onError: (error, stackChain) {
    print("Caught error $error\n"
        "${stackChain.terse}");
  });
//  runZoned(() {
//    main123();
//  }, onError: (e, st) {
//    Logger.root.severe(e, st);
//
//    new Chain.forTrace(st).;
//  });
}
main123() async {
  spec.ProjectGroupRef ref = new spec.ProjectGroupRef.fromGitUrl('gitbacklog',
      '/Users/blah/dart/jefe_jefe/jefe_test_projects/local/gitbacklog');

  final Directory installDir = await Directory.systemTemp.createTemp();

  print(installDir);

  final ProjectGroup projectGroup =
      await ProjectGroup.install(installDir, ref.name, ref.gitUri);

  print('installed group => $projectGroup');

  print('container dir = ${projectGroup.containerDirectory}');

  print(
      '********* childGroups ${await (projectGroup as ProjectGroupImpl).childGroups.first.get()}');
  print('********* allProjects ${await projectGroup.allProjects}');

//  await projectGroup.install(installDir);
//  await projectGroup.setupForDev();

  final ProjectGroup projectGroup2 =
      await ProjectGroup.load(projectGroup.containerDirectory);

  print('loaded group => $projectGroup2');

  print('container dir = ${projectGroup2.containerDirectory}');

  print('+++++++++ allProjects ${await projectGroup2.allProjects}');

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
