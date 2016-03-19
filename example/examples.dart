// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library example;

import 'dart:async';
import 'dart:io';

import 'package:jefe/jefe.dart';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';

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

  final graph = await projectGroup.rootJefeProjects;

  // initialise it (sets it on develop branch etc)
  await graph.lifecycle.init();

  // start a new feature
  // All projects will be on a feature branch called feacha,
  // will have the dependencies to other projects in this group set as
  // path dependencies, and will have pub get called
  await graph.lifecycle.startNewFeature('feacha');

  // Code something awesome

  // finish off the feature
  // All projects will have their feature branches merged to develop,
  // will have the dependencies to other projects in this group set as
  // git dependencies bashed on the current commit hash,
  // will be git pushed to their origin
  // and will have pub get called
  await graph.lifecycle.completeFeature();

  // now cut a release.
  // All the project pubspec versions will be bumped according to the release type
  // and git tagged with same version, will be merged to master
  await graph.lifecycle.release(type: ReleaseType.major);
}

Future generateProductionDockerfile() async {
  final ProjectGroup projectGroup =
      await ProjectGroup.load(new Directory('/Users/blah/myfoo_root'));

  final graph = await projectGroup.rootJefeProjects;

  await graph.multiProjectCommands().docker.generateProductionDockerfile(
      'my_server', 'my_client',
      outputDirectory: new Directory('/tmp'),
      dartVersion: '1.9.3',
      environment: {'MY_FOO': false},
      exposePorts: [8080, 8181, 5858],
      entryPointOptions: ["--debug:5858/0.0.0.0"]);
}
