library example;

import 'dart:io';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:devops/devops.dart';
import 'dart:async';

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(print);
  hierarchicalLoggingEnabled = true;

  Chain.capture(() async {
    await generateProductionDockerfile();
  }, onError: (error, stackChain) {
    print("Caught error $error\n"
        "${stackChain.terse}");
  });
}

Future projectLifecycleBasics() async {
  // first install the project groupd
  final ProjectGroup projectGroup = await ProjectGroup.install(
      new Directory('/Users/blah'), 'git@git.example');

  final executor = new CommandExecutor(projectGroup);

  // initialise it (sets it on develop branch etc)
  await executor.executeAll(lifecycle.init());

  // start a new feature
  // All projects will be on a feature branch called feacha,
  // will have the dependencies to other projects in this group set as
  // path dependencies, and will have pub get called
  await executor.executeAll(lifecycle.startNewFeature('feacha'));

  // Code something awesome

  // finish off the feature
  // All projects will have their feature branches merged to develop,
  // will have the dependencies to other projects in this group set as
  // git dependencies bashed on the current commit hash,
  // will be git pushed to their origin
  // and will have pub get called
  await executor.execute(lifecycle.completeFeature('feacha'));

  // now cut a release.
  // All the project pubspec versions will be bumped according to the release type
  // and git tagged with same version, will be merged to master
  await executor.execute(lifecycle.release(type: ReleaseType.major));
}

Future generateProductionDockerfile() async {
  final executor = await executorForDirectory('/Users/blah/myfoo_root');

  await executor.executeOnGraph(docker.generateProductionDockerfile(
      'my_server', 'my_client',
      outputDirectory: new Directory('/tmp'),
      dartVersion: '1.9.3',
      environment: {'MY_FOO': false},
      exposePorts: [8080, 8181, 5858],
      entryPointOptions: ["--debug:5858/0.0.0.0"]));
}
