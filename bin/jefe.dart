// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:jefe/jefe.dart';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:unscripted/unscripted.dart' as u;
import 'package:jefe/src/project/jefe_project.dart';

main(List<String> arguments) {
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
  install(
      @u.Positional(help: 'The git Uri containing the jefe.yaml.')
          String gitUri,
      {@u.Option(help: 'The directory to install into', abbr: 'd')
          String installDirectory: '.'}) async {
    final Directory installDir = new Directory(installDirectory);
    final ProjectGroup projectGroup =
        await ProjectGroup.install(installDir, gitUri);

    await (await projectGroup.rootJefeProjects).lifecycle.init();
//    final executor = new CommandExecutor(projectGroup);
//    await executor.execute(lifecycle.init());
  }

  @u.SubCommand(help: 'Installs or updates a group of projects')
  init(
      {@u.Option(help: 'The git Uri containing the jefe.yaml.', abbr: 'g')
          String gitUri,
      @u.Option(help: 'The directory to install into', abbr: 'd')
          String installDirectory: '.',
      @u.Flag(help: 'Skips the checkout of the develop branch', abbr: 's')
          bool skipCheckout: false}) async {
    final Directory installDir = new Directory(installDirectory);
    final ProjectGroup projectGroup =
        await ProjectGroup.init(installDir, gitUri);

//    final executor = new CommandExecutor(projectGroup);
//    await executor.execute(lifecycle.init(doCheckout: !skipCheckout));
    await (await projectGroup.rootJefeProjects)
        .lifecycle
        .init(doCheckout: !skipCheckout);
  }

  @u.SubCommand(help: 'Sets up for the start of development on a new feature')
  start(
      String featureName,
      {@u.Option(help: 'The directory that contains the root of the projecs', abbr: 'd')
          String rootDirectory: '.',
      @u.Option(help: 'A project name filter. Only projects whose name contains the text will run', abbr: 'p')
          String projects}) async {
    final graph = await _loadGraph(rootDirectory);
    return graph
        .multiProjectCommands(projectFilter: projectNameFilter(projects))
        .lifecycle
        .startNewFeature(featureName);
  }

  @u.SubCommand(help: 'Completes feature and returns to development branch')
  finish(
      {@u.Option(help: 'The directory that contains the root of the projects', abbr: 'd')
          String rootDirectory: '.',
      @u.Option(help: 'A project name filter. Only projects whose name contains the text will run', abbr: 'p')
          String projects}) async {
    final graph = await _loadGraph(rootDirectory);
    return graph
        .multiProjectCommands(projectFilter: projectNameFilter(projects))
        .lifecycle
        .completeFeature();
  }

  @u.SubCommand(help: 'Create a release of all the projects')
  release(
      {@u.Option(help: 'The directory that contains the root of the projecs', abbr: 'd')
          String rootDirectory: '.',
      @u.Option(help: 'The type of release', abbr: 't', defaultsTo: ReleaseType.lowest, parser: _parseReleaseType)
          ReleaseType type: ReleaseType.lowest,
      @u.Option(help: 'A project name filter. Only projects whose name contains the text will run', abbr: 'p')
          String projects,
      @u.Flag(help: 'if true then only pre release verification steps are executed', defaultsTo: false)
          bool preReleaseOnly: false,
      @u.Flag(help: 'if true then the pre release verification steps are skipped', defaultsTo: false)
          bool skipPreRelease: false,
      @u.Flag(help: 'if true then version numbers of hosted packages will also be updated', defaultsTo: false)
          bool autoUpdateHostedVersions: false}) async {
    final graph = await _loadGraph(rootDirectory);

    final lifecycle = graph
        .multiProjectCommands(projectFilter: projectNameFilter(projects))
        .lifecycle;

    // TODO: would be nice to leverage grinder here (command dependencies)
    // somehow

    if (!skipPreRelease) {
      await lifecycle.preRelease(
          type: type, autoUpdateHostedVersions: autoUpdateHostedVersions);
    }

    if (!preReleaseOnly) {
      await lifecycle.release(
          type: type, autoUpdateHostedVersions: autoUpdateHostedVersions);
    } else {
      print('-------');
    }
  }

  @u.SubCommand(help: 'Runs the given command in all projects')
  exec(
      String command,
      @u.Rest()
          List<String> args,
      {@u.Option(help: 'The directory that contains the root of the projecs', abbr: 'd')
          String rootDirectory: '.',
      @u.Option(help: 'A project name filter. Only projects whose name contains the text will run', abbr: 'p')
          String projects,
      @u.Flag(help: 'Instead of running the commands concurrently on the projects, run only one command on one project at a time', abbr: 's')
          bool executeSerially: false}) async {
    final graph = await _loadGraph(rootDirectory);

    final processCommands = graph
        .multiProjectCommands(
            projectFilter: projectNameFilter(projects),
            defaultConcurrencyMode: executeSerially
                ? CommandConcurrencyMode.serialDepthFirst
                : CommandConcurrencyMode.concurrentProject)
        .processCommands;

    return processCommands.execute(command, args);
  }

  @u.SubCommand(help: 'Set dependencies between projects')
  setDependencies(
      @u.Positional(help: 'The type of dependency to set', allowed: const [
    'git',
    'path',
    'hosted'
  ])
          String type,
      {@u.Option(help: 'The directory that contains the root of the projecs', abbr: 'd')
          String rootDirectory: '.',
      @u.Option(help: 'A project name filter. Only projects whose name contains the text will run', abbr: 'p')
          String projects}) async {
    final graph = await _loadGraph(rootDirectory);
    final pubSpec = graph
      .multiProjectCommands(projectFilter: projectNameFilter(projects))
      .pubspecCommands;

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

  @u.SubCommand(help: 'Runs tests projects that have tests')
  test(
      {@u.Option(help: 'The directory that contains the root of the projecs', abbr: 'd')
          String rootDirectory: '.',
      @u.Option(help: 'A project name filter. Only projects whose name contains the text will run', abbr: 'p')
          String projects}) async {
    final graph = await _loadGraph(rootDirectory);

    return graph.pub.test();
  }

//  Future<CommandExecutor> _loadExecutor(String rootDirectory) async =>
//      new CommandExecutor(await _load(rootDirectory));

  Future<JefeProjectGraph> _loadGraph(String rootDirectory) async =>
      await (await _load(rootDirectory)).rootJefeProjects;

  Future<ProjectGroup> _load(String rootDirectory) async {
    final Directory installDir =
        rootDirectory == '.' ? Directory.current : new Directory(rootDirectory);
    return ProjectGroup.load(installDir);
  }
}

ReleaseType _parseReleaseType(String str) => ReleaseType.fromLiteral(str).get();
