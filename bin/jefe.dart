// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:unscripted/unscripted.dart';
import 'dart:io';
import 'package:jefe/jefe.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'package:stack_trace/stack_trace.dart';

main(arguments) {
  Chain.capture(() {
    new Script(Jefe).execute(arguments);
  }, onError: (error, stackChain) {
    print("Caught error $error\n"
        "${stackChain.terse}");
  });
}

class Jefe {
  @Command(
      help: 'Manages a set of related Dart projects',
      plugins: const [const Completion()])
  Jefe() {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((cr) {
      print('${cr.time}: ${cr.message}');
    });
    hierarchicalLoggingEnabled = true;
  }

  @SubCommand(help: 'Installs a group of projects')
  install(
      @Positional(help: 'The git Uri containing the jefe.yaml.') String gitUri,
      {@Option(
          help: 'The directory to install into',
          abbr: 'd') String installDirectory: '.'}) async {
    final Directory installDir = new Directory(installDirectory);
    final ProjectGroup projectGroup =
        await ProjectGroup.install(installDir, gitUri);

    final executor = new CommandExecutor(projectGroup);
    await executor.executeAll(lifecycle.init());
  }

  @SubCommand(help: 'Installs or updates a group of projects')
  init({@Option(
      help: 'The git Uri containing the jefe.yaml.',
      abbr: 'g') String gitUri, @Option(
      help: 'The directory to install into',
      abbr: 'd') String installDirectory: '.'}) async {
    final Directory installDir = new Directory(installDirectory);
    final ProjectGroup projectGroup =
        await ProjectGroup.init(installDir, gitUri);

    final executor = new CommandExecutor(projectGroup);
    await executor.executeAll(lifecycle.init());
  }

  @SubCommand(help: 'Sets up for the start of development on a new feature')
  start(String featureName, {@Option(
      help: 'The directory that contains the root of the projecs',
      abbr: 'd') String rootDirectory: '.', @Option(
      help: 'A project name filter. Only projects whose name contains the text will run',
      abbr: 'p') String projects}) async {
    final executor = await load(rootDirectory);
    await executor.executeAll(lifecycle.startNewFeature(featureName),
        filter: projectNameFilter(projects));
  }

  @SubCommand(help: 'Completes feature and returns to development branch')
  finish(String featureName, {@Option(
      help: 'The directory that contains the root of the projects',
      abbr: 'd') String rootDirectory: '.', @Option(
      help: 'A project name filter. Only projects whose name contains the text will run',
      abbr: 'p') String projects}) async {
    final executor = await load(rootDirectory);
    await executor.execute(lifecycle.completeFeature(featureName),
        filter: projectNameFilter(projects));
  }

  @SubCommand(help: 'Create a release of all the projects')
  release({@Option(
      help: 'The directory that contains the root of the projecs',
      abbr: 'd') String rootDirectory: '.', @Option(
      help: 'A project name filter. Only projects whose name contains the text will run',
      abbr: 'p') String projects}) async {
    final executor = await load(rootDirectory);
    await executor.execute(lifecycle.release(),
        filter: projectNameFilter(projects));
  }

  @SubCommand(help: 'Runs the given command in all projects')
  exec(String command, @Rest() List<String> args, {@Option(
      help: 'The directory that contains the root of the projecs',
      abbr: 'd') String rootDirectory: '.', @Option(
      help: 'A project name filter. Only projects whose name contains the text will run',
      abbr: 'p') String projects, @Flag(
      help: 'Instead of running the commands concurrently on the projects, run only one command on one project at a time',
      abbr: 's') bool executeSerially: false}) async {
    final CommandExecutor executor = await load(rootDirectory);
    await executor.execute(process.process(command, args),
        filter: projectNameFilter(projects),
        concurrencyMode: executeSerially
            ? CommandConcurrencyMode.serial
            : CommandConcurrencyMode.concurrentProject);
  }

  Future<CommandExecutor> load(String rootDirectory) async {
    final Directory installDir =
        rootDirectory == '.' ? Directory.current : new Directory(rootDirectory);
    final ProjectGroup projectGroup = await ProjectGroup.load(installDir);

    final executor = new CommandExecutor(projectGroup);
    return executor;
  }
}
