library devops.project.test;

import 'package:devops/src/project.dart';
import 'dart:io';
import 'package:devops/src/git/git.dart';
import 'package:path/path.dart' as p;
import 'package:git/git.dart';
import 'package:logging/logging.dart';
import 'package:devops/src/spec/JefeSpec.dart' as spec;
import 'package:stack_trace/stack_trace.dart';
import 'package:devops/src/project_operations/project_command_executor.dart';
import 'package:devops/src/project_operations/project_lifecycle.dart';
import 'package:devops/src/project_operations/docker_commands.dart';

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
  final ProjectGroup projectGroup = await ProjectGroup
      .load(new Directory('/Users/blah/dart/newbacklogio/gitbacklog_root'));

  final executor = new CommandExecutor(projectGroup);

  Map<String, dynamic> environment = {'USE_PUB_SERVE_IN_DEV': false};
  Iterable<int> exposePorts = [8080, 8181, 5858];
  Iterable<String> entryPointOptions = ["--debug:5858/0.0.0.0"];

  final docker = new DockerCommands();
  final genDocker = docker.generateDockerfile(
      'gitbacklog_server', 'gitbacklog_client',
      outputDirectory: new Directory('/Users/blah/dart/jefe_jefe'),
      dartVersion: '1.9.1',
      environment: environment,
      exposePorts: exposePorts,
      entryPointOptions: entryPointOptions);

  await executor.executeOnGraph(genDocker);
}

main123ff() async {
  final Directory installDir = await Directory.systemTemp.createTemp();
//  final Directory installDir = new Directory('/Users/blah/dart/newbacklogio');
  final ProjectGroup projectGroup = await ProjectGroup.install(installDir,
      '/Users/blah/dart/jefe_jefe/jefe_test_projects/local/gitbacklog');

  final executor = new CommandExecutor(projectGroup);

  final lifecycle = new ProjectLifecycle();

  await executor.executeAll(lifecycle.init());
  await executor.executeAll(lifecycle.startNewFeature('feacha'));
  await executor.execute(lifecycle.completeFeature('feacha'));
}
