// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:jefe/jefe.dart';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:unscripted/unscripted.dart' as u;

main(arguments) {
  Chain.capture(() {
    new u.Script(Jefe).execute(arguments);
  }, onError: (error, stackChain) {
    if (error is ProjectCommandError) {
      print(error);
    } else {
      print("Caught error $error\n"
          "${stackChain.terse}");
    }
  });
}

class Jefe {
  @u.Command(
      help: 'Manages a set of related Dart projects',
      plugins: const [const u.Completion()])
  Jefe() {
    Logger.root.level = Level.FINEST;
    Logger.root.onRecord.listen((cr) {
      print('${cr.time}: ${cr.message}');
    });
    hierarchicalLoggingEnabled = true;
  }

  @u.SubCommand(help: 'Installs a group of projects')
  install(@u.Positional(
          help: 'The git Uri containing the jefe.yaml.') String gitUri,
      {@u.Option(
          help: 'The directory to install into',
          abbr: 'd') String installDirectory: '.'}) async {
    final Directory installDir = new Directory(installDirectory);
    final ProjectGroup projectGroup =
        await ProjectGroup.install(installDir, gitUri);

    final executor = new CommandExecutor(projectGroup);
    await executor.execute(lifecycle.init());
  }

  @u.SubCommand(help: 'Installs or updates a group of projects')
  init(
      {@u.Option(
          help: 'The git Uri containing the jefe.yaml.',
          abbr: 'g') String gitUri,
      @u.Option(
          help: 'The directory to install into',
          abbr: 'd') String installDirectory: '.',
      @u.Flag(
          help: 'Skips the checkout of the develop branch',
          abbr: 's') bool skipCheckout: false}) async {
    final Directory installDir = new Directory(installDirectory);
    final ProjectGroup projectGroup =
        await ProjectGroup.init(installDir, gitUri);

    final executor = new CommandExecutor(projectGroup);
    await executor.execute(lifecycle.init(doCheckout: !skipCheckout));
  }

  @u.SubCommand(help: 'Sets up for the start of development on a new feature')
  start(String featureName,
      {@u.Option(
          help: 'The directory that contains the root of the projecs',
          abbr: 'd') String rootDirectory: '.',
      @u.Option(
          help: 'A project name filter. Only projects whose name contains the text will run',
          abbr: 'p') String projects}) async {
    final executor = await _load(rootDirectory);
    await executor.execute(lifecycle.startNewFeature(featureName),
        filter: projectNameFilter(projects));
  }

  @u.SubCommand(help: 'Completes feature and returns to development branch')
  finish(String featureName,
      {@u.Option(
          help: 'The directory that contains the root of the projects',
          abbr: 'd') String rootDirectory: '.',
      @u.Option(
          help: 'A project name filter. Only projects whose name contains the text will run',
          abbr: 'p') String projects}) async {
    final executor = await _load(rootDirectory);
    await executor.execute(lifecycle.completeFeature(featureName),
        filter: projectNameFilter(projects));
  }

  @u.SubCommand(help: 'Create a release of all the projects')
  release(
      {@u.Option(
          help: 'The directory that contains the root of the projecs',
          abbr: 'd') String rootDirectory: '.',
      @u.Option(
          help: 'The type of release',
          abbr: 't',
          defaultsTo: ReleaseType.lowest,
          parser: _parseReleaseType) ReleaseType type: ReleaseType.lowest,
      @u.Option(
          help: 'A project name filter. Only projects whose name contains the text will run',
          abbr: 'p') String projects,
      @u.Flag(
          help: 'if true then only pre release verification steps are executed',
          defaultsTo: false) bool preReleaseOnly: false,
      @u.Flag(
          help: 'if true then the pre release verification steps are skipped',
          defaultsTo: false) bool skipPreRelease: false,
      @u.Flag(
          help: 'if true then version numbers of hosted packages will also be updated',
          defaultsTo: false) bool autoUpdateHostedVersions: false}) async {
    final executor = await _load(rootDirectory);
    // TODO: would be nice to leverage grinder here (command dependencies)
    // somehow
    if (!skipPreRelease) {
      await executor.execute(lifecycle.preRelease(
              type: type, autoUpdateHostedVersions: autoUpdateHostedVersions),
          filter: projectNameFilter(projects));
    }

    if (!preReleaseOnly) {
      await executor.execute(lifecycle.release(
              type: type, autoUpdateHostedVersions: autoUpdateHostedVersions),
          filter: projectNameFilter(projects));
    } else {
      print('-------');
    }
  }

  @u.SubCommand(help: 'Runs the given command in all projects')
  exec(String command, @u.Rest() List<String> args,
      {@u.Option(
          help: 'The directory that contains the root of the projecs',
          abbr: 'd') String rootDirectory: '.',
      @u.Option(
          help: 'A project name filter. Only projects whose name contains the text will run',
          abbr: 'p') String projects,
      @u.Flag(
          help: 'Instead of running the commands concurrently on the projects, run only one command on one project at a time',
          abbr: 's') bool executeSerially: false}) async {
    final CommandExecutor executor = await _load(rootDirectory);
    await executor.execute(process.process(command, args),
        filter: projectNameFilter(projects),
        concurrencyMode: executeSerially
            ? CommandConcurrencyMode.serial
            : CommandConcurrencyMode.concurrentProject);
  }

  @u.SubCommand(help: 'Set dependencies between projects')
  setDependencies(@u.Positional(
          help: 'The type of dependency to set',
          allowed: const ['git', 'path', 'hosted']) String type,
      {@u.Option(
          help: 'The directory that contains the root of the projecs',
          abbr: 'd') String rootDirectory: '.',
      @u.Option(
          help: 'A project name filter. Only projects whose name contains the text will run',
          abbr: 'p') String projects}) async {
    final CommandExecutor executor = await _load(rootDirectory);
    final command = _setToDependencyCommand(type);
    await executor.execute(command,
        filter: projectNameFilter(projects),
        concurrencyMode: CommandConcurrencyMode.serial);
  }

  @u.SubCommand(help: 'Runs tests projects that have tests')
  test(
      {@u.Option(
          help: 'The directory that contains the root of the projecs',
          abbr: 'd') String rootDirectory: '.',
      @u.Option(
          help: 'A project name filter. Only projects whose name contains the text will run',
          abbr: 'p') String projects}) async {
    final CommandExecutor executor = await _load(rootDirectory);
    await executor.execute(pub.test(), filter: projectNameFilter(projects));
  }

  Future<CommandExecutor> _load(String rootDirectory) async {
    final Directory installDir =
        rootDirectory == '.' ? Directory.current : new Directory(rootDirectory);
    final ProjectGroup projectGroup = await ProjectGroup.load(installDir);

    final executor = new CommandExecutor(projectGroup);
    return executor;
  }

  ProjectCommand _setToDependencyCommand(String type) {
    switch (type) {
      case 'git':
        return pubSpec.setToGitDependencies();
      case 'hosted':
        return pubSpec.setToHostedDependencies();
      case 'path':
      default:
        return pubSpec.setToPathDependencies();
    }
  }
}

ReleaseType _parseReleaseType(String str) => ReleaseType.fromLiteral(str).get();
