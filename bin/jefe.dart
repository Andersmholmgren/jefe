// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:jefe/jefe.dart' hide Command;
import 'package:jefe/src/project/jefe_project.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:stack_trace/stack_trace.dart';

//import 'package:unscripted/unscripted.dart' as u;
import 'package:args/args.dart';
import 'package:args/command_runner.dart';

main(List<String> arguments) {
  final runner =
      CommandRunner('jefe', 'Manages a set of related Dart projects');
  runner
    ..addCommand(Install())
    ..addCommand(Init())
    ..addCommand(Jefetise())
    ..addCommand(Start())
    ..addCommand(Finish())
    ..addCommand(Exec());

  Chain.capture(() {
    runner.run(arguments);
  }, onError: (error, stackChain) {
    if (error is ProjectCommandError) {
      print(error);
    } else {
      print("Caught error $error\n"
          "${stackChain.terse}");
    }
  });
}

class Install extends Command {
  final name = "install";
  final description = "Installs a group of projects";

  Install() {
    argParser.addOption('gitUri',
        help: 'The git Uri containing the jefe.yaml.', abbr: 'g');
    argParser.addOption('installDirectory',
        help: 'The directory to install into', abbr: 'd', defaultsTo: '.');
  }

  Future run() {
    final gitUri = argResults['gitUri'];
    final installDirectory = argResults['installDirectory'];
    return install(gitUri, installDirectory: installDirectory);
  }

  Future install(String gitUri, {String installDirectory: '.'}) async {
    final Directory installDir = new Directory(installDirectory);
    final ProjectGroup projectGroup =
        await ProjectGroup.install(installDir, gitUri);

    await (await projectGroup.rootJefeProjects).lifecycle.init();
  }
}

class Jefetise extends Command {
  final name = "jefetise";
  final description = 'Converts a directory of projects into a jefe group. '
      'WARNING renames the current directory to append _root to name';

  Jefetise() {
    argParser.addOption('containerDirectory',
        help: 'The directory that contains the projects',
        abbr: 'd',
        defaultsTo: '.');
  }

  Future run() {
    final containerDirectory = argResults['containerDirectory'];
    return jefetise(containerDirectory: containerDirectory);
  }

  Future jefetise({String containerDirectory: '.'}) async {
    final Directory parentDir = new Directory(containerDirectory);
    await ProjectGroup.jefetize(parentDir);
  }
}

class Init extends Command {
  final name = "init";
  final description = 'Installs or updates a group of projects';

  Init() {
    argParser.addOption('gitUri',
        help: 'The git Uri containing the jefe.yaml.', abbr: 'g');
    argParser.addOption('installDirectory',
        help: 'The directory to install into', abbr: 'd', defaultsTo: '.');
    argParser.addFlag('skipCheckout',
        help: 'Skips the checkout of the develop branch',
        abbr: 's',
        defaultsTo: false);
  }

  Future run() {
    final gitUri = argResults['gitUri'];
    final installDirectory = argResults['installDirectory'];
    final skipCheckout = argResults['skipCheckout'];
    return init(
        gitUri: gitUri,
        installDirectory: installDirectory,
        skipCheckout: skipCheckout);
  }

  init(
      {String gitUri,
      String installDirectory: '.',
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
}

class Start extends Command {
  final name = "start";
  final description = 'Sets up for the start of development on a new feature';

  Start() {
    argParser.addOption('featureName',
        help: 'The name of the feature to start', abbr: 'f');
    argParser.addOption('rootDirectory',
        help: 'The directory that contains the root of the projecs',
        abbr: 'd',
        defaultsTo: '.');
    argParser.addOption('projects',
        help:
            'A project name filter. Only projects whose name contains the text will run',
        abbr: 'p');
  }

  Future run() {
    final featureName = argResults['featureName'];
    final rootDirectory = argResults['rootDirectory'];
    final projects = argResults['projects'];
    return start(featureName, rootDirectory: rootDirectory, projects: projects);
  }

  start(String featureName,
      {String rootDirectory: '.', String projects}) async {
    final graph = await _loadGraph(rootDirectory);
    return graph
        .multiProjectCommands(projectFilter: projectNameFilter(projects))
        .lifecycle
        .startNewFeature(featureName);
  }
}

class Finish extends Command {
  final name = "finish";
  final description = 'Completes feature and returns to development branch';

  Finish() {
    argParser.addOption('rootDirectory',
        help: 'The directory that contains the root of the projecs',
        abbr: 'd',
        defaultsTo: '.');
    argParser.addOption('projects',
        help:
            'A project name filter. Only projects whose name contains the text will run',
        abbr: 'p');
  }

  Future run() {
    final rootDirectory = argResults['rootDirectory'];
    final projects = argResults['projects'];
    return finish(rootDirectory: rootDirectory, projects: projects);
  }

  finish({String rootDirectory: '.', String projects}) async {
    final graph = await _loadGraph(rootDirectory);
    return graph
        .multiProjectCommands(projectFilter: projectNameFilter(projects))
        .lifecycle
        .completeFeature();
  }
}

class Exec extends Command {
  final name = "exec";
  final description = 'Runs the given command in all projects';

  Exec() {
    argParser.addOption('command', help: 'The command to execute', abbr: 'c');
    argParser.addOption('rootDirectory',
        help: 'The directory that contains the root of the projecs',
        abbr: 'd',
        defaultsTo: '.');
    argParser.addOption('projects',
        help:
            'A project name filter. Only projects whose name contains the text will run',
        abbr: 'p');
    argParser.addFlag('executeSerially',
        help:
            'Instead of running the commands concurrently on the projects, run only one command on one project at a time',
        abbr: 's',
        defaultsTo: false);
  }

  Future run() {
    final commandArgs = argResults.rest.toList();
    final command = argResults['command'];
    final rootDirectory = argResults['rootDirectory'];
    final projects = argResults['projects'];
    final executeSerially = argResults['executeSerially'];
    final fred = 'fuck';

    return exec(command, commandArgs,
        rootDirectory: rootDirectory,
        projects: projects,
        executeSerially: executeSerially);
  }

  exec(String command, List<String> args,
      {String rootDirectory: '.',
      String projects,
      bool executeSerially: false}) async {
    final graph = await _loadGraph(rootDirectory);

    final processCommands = graph
        .multiProjectCommands(
            projectFilter: projectNameFilter(projects),
            defaultConcurrencyMode: executeSerially
                ? CommandConcurrencyMode.serialDepthFirst
                : CommandConcurrencyMode.concurrentProject)
        .processCommands;

    final result = await processCommands.execute(command, args);
    final output = result.map((r) => r.toReportString()).join('\n');
    stdout.write(output);
  }
}

//class Jefe extends Command {
//  // TODO: implement name
//  @override
//  String get name => null;
//
//  @u.Command(
//      help: 'Manages a set of related Dart projects',
//      plugins: const [const u.Completion()])
//  Jefe() {
//    Logger.root.level = Level.FINEST;
//    Logger.root.onRecord.listen((cr) {
//      print('${cr.time}: ${cr.message}');
//    });
//    hierarchicalLoggingEnabled = true;
//  }

//  @u.SubCommand(help: 'Installs a group of projects')
//  install(
//      @u.Positional(help: 'The git Uri containing the jefe.yaml.')
//          String gitUri,
//      {@u.Option(help: 'The directory to install into', abbr: 'd')
//          String installDirectory: '.'}) async {
//    final Directory installDir = new Directory(installDirectory);
//    final ProjectGroup projectGroup =
//        await ProjectGroup.install(installDir, gitUri);
//
//    await (await projectGroup.rootJefeProjects).lifecycle.init();
//  }

//  @u.SubCommand(
//      help: 'Converts a directory of projects into a jefe group. '
//          'WARNING renames the current directory to append _root to name')
//  jefetise({@u.Option(help: 'The directory that contains the projects',
//      abbr: 'd') String containerDirectory: '.'}) async {
//    final Directory parentDir = new Directory(containerDirectory);
//    await ProjectGroup.jefetize(parentDir);
//  }

//  @u.SubCommand(help: 'Installs or updates a group of projects')
//  init({@u.Option(
//      help: 'The git Uri containing the jefe.yaml.', abbr: 'g') String gitUri,
//    @u.Option(help: 'The directory to install into',
//        abbr: 'd') String installDirectory: '.',
//    @u.Flag(help: 'Skips the checkout of the develop branch',
//        abbr: 's') bool skipCheckout: false}) async {
//    final Directory installDir = new Directory(installDirectory);
//    final ProjectGroup projectGroup =
//    await ProjectGroup.init(installDir, gitUri);
//
////    final executor = new CommandExecutor(projectGroup);
////    await executor.execute(lifecycle.init(doCheckout: !skipCheckout));
//    await (await projectGroup.rootJefeProjects)
//        .lifecycle
//        .init(doCheckout: !skipCheckout);
//  }

//  @u.SubCommand(help: 'Sets up for the start of development on a new feature')
//  start(String featureName,
//      {@u.Option(help: 'The directory that contains the root of the projecs',
//          abbr: 'd') String rootDirectory: '.',
//        @u.Option(
//            help: 'A project name filter. Only projects whose name contains the text will run',
//            abbr: 'p') String projects}) async {
//    final graph = await _loadGraph(rootDirectory);
//    return graph
//        .multiProjectCommands(projectFilter: projectNameFilter(projects))
//        .lifecycle
//        .startNewFeature(featureName);
//  }
//
//  @u.SubCommand(help: 'Completes feature and returns to development branch')
//  finish({@u.Option(
//      help: 'The directory that contains the root of the projects',
//      abbr: 'd') String rootDirectory: '.',
//    @u.Option(
//        help: 'A project name filter. Only projects whose name contains the text will run',
//        abbr: 'p') String projects}) async {
//    final graph = await _loadGraph(rootDirectory);
//    return graph
//        .multiProjectCommands(projectFilter: projectNameFilter(projects))
//        .lifecycle
//        .completeFeature();
//  }
//
// ------- up to

//  @u.SubCommand(help: 'Create a release of all the projects')
//  release({@u.Option(
//      help: 'The directory that contains the root of the projecs',
//      abbr: 'd') String rootDirectory: '.',
//    @u.Option(help: 'The type of release',
//        abbr: 't',
//        defaultsTo: ReleaseType.lowest,
//        parser: _parseReleaseType) ReleaseType type: ReleaseType.lowest,
//    @u.Option(
//        help: 'A project name filter. Only projects whose name contains the text will run',
//        abbr: 'p') String projects,
//    @u.Flag(
//        help: 'if true then only pre release verification steps are executed',
//        defaultsTo: false) bool preReleaseOnly: false,
//    @u.Flag(help: 'if true then the pre release verification steps are skipped',
//        defaultsTo: false) bool skipPreRelease: false,
//    @u.Flag(
//        help: 'if true then version numbers of hosted packages will also be updated',
//        defaultsTo: false) bool autoUpdateHostedVersions: false}) async {
//    final graph = await _loadGraph(rootDirectory);
//
//    final lifecycle = graph
//        .multiProjectCommands(projectFilter: projectNameFilter(projects))
//        .lifecycle;
//
//    // TODO: would be nice to leverage grinder here (command dependencies)
//    // somehow
//
//    if (!skipPreRelease) {
//      await lifecycle.preRelease(
//          type: type, autoUpdateHostedVersions: autoUpdateHostedVersions);
//    }
//
//    if (!preReleaseOnly) {
//      await lifecycle.release(
//          type: type, autoUpdateHostedVersions: autoUpdateHostedVersions);
//    } else {
//      print('-------');
//    }
//  }
//
//  @u.SubCommand(help: 'Runs the given command in all projects')
//  exec(String command,
//      @u.Rest() List<String> args,
//      {@u.Option(help: 'The directory that contains the root of the projecs',
//          abbr: 'd') String rootDirectory: '.',
//        @u.Option(
//            help: 'A project name filter. Only projects whose name contains the text will run',
//            abbr: 'p') String projects,
//        @u.Flag(
//            help: 'Instead of running the commands concurrently on the projects, run only one command on one project at a time',
//            abbr: 's') bool executeSerially: false}) async {
//    final graph = await _loadGraph(rootDirectory);
//
//    final processCommands = graph
//        .multiProjectCommands(
//        projectFilter: projectNameFilter(projects),
//        defaultConcurrencyMode: executeSerially
//            ? CommandConcurrencyMode.serialDepthFirst
//            : CommandConcurrencyMode.concurrentProject)
//        .processCommands;
//
//    final result = await processCommands.execute(command, args);
//    final output = result.map((r) => r.toReportString()).join('\n');
//    stdout.write(output);
//  }
//
//  @u.SubCommand(help: 'Set dependencies between projects')
//  setDependencies(
//      @u.Positional(help: 'The type of dependency to set', allowed: const [
//        'git',
//        'path',
//        'hosted'
//      ]) String type,
//      {@u.Option(help: 'The directory that contains the root of the projecs',
//          abbr: 'd') String rootDirectory: '.',
//        @u.Option(
//            help: 'A project name filter. Only projects whose name contains the text will run',
//            abbr: 'p') String projects}) async {
//    final graph = await _loadGraph(rootDirectory);
//    final pubSpec = graph
//        .multiProjectCommands(projectFilter: projectNameFilter(projects))
//        .pubspecCommands;
//
//    switch (type) {
//      case 'git':
//        return pubSpec.setToGitDependencies();
//      case 'hosted':
//        return pubSpec.setToHostedDependencies();
//      case 'path':
//      default:
//        return pubSpec.setToPathDependencies();
//    }
//  }
//
//  @u.SubCommand(help: 'Runs tests projects that have tests')
//  test({@u.Option(help: 'The directory that contains the root of the projecs',
//      abbr: 'd') String rootDirectory: '.',
//    @u.Option(
//        help: 'A project name filter. Only projects whose name contains the text will run',
//        abbr: 'p') String projects}) async {
//    final graph = await _loadGraph(rootDirectory);
//    final pub = graph
//        .multiProjectCommands(projectFilter: projectNameFilter(projects))
//        .pub;
//
//    return pub.test();
//  }
//
//  @u.SubCommand(help: 'Creates the Intellij vcs.xml file for project group')
//  intellijVcs({@u.Option(
//      help: 'The directory that contains the root of the projecs',
//      abbr: 'd') String rootDirectory: '.',
//    @u.Option(
//        help: 'A project name filter. Only projects whose name contains the text will run',
//        abbr: 'p') String projects}) async {
//    final group = await _load(rootDirectory);
//
//    final File vcsFile =
//    new File(p.join(group.containerDirectory.path, '.idea', 'vcs.xml'));
//
//    final graph = await group.rootJefeProjects;
//
//    final intellij = graph
//        .multiProjectCommands(projectFilter: projectNameFilter(projects))
//        .intellijCommands;
//
//    final mappings =
//    await intellij.generateGitMappings(group.containerDirectory.path);
//
//    final sink = vcsFile.openWrite();
//    sink.write(mappings.toXmlString());
//    return sink.close();
//  }
//

Future<CommandExecutor> _loadExecutor(String rootDirectory) async =>
    new CommandExecutor(await _load(rootDirectory));

Future<JefeProjectGraph> _loadGraph(String rootDirectory) async =>
    await (await _load(rootDirectory)).rootJefeProjects;

Future<ProjectGroup> _load(String rootDirectory) async {
  final Directory installDir =
      rootDirectory == '.' ? Directory.current : new Directory(rootDirectory);
  return ProjectGroup.load(installDir);
}

ReleaseType _parseReleaseType(String str) => ReleaseType.fromLiteral(str).value;
