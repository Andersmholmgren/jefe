// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:jefe/jefe.dart' hide Command;
import 'package:jefe/src/project/jefe_project.dart';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';

main(List<String> arguments) {
  Logger.root.level = Level.FINEST;
  Logger.root.onRecord.listen((cr) {
    print('${cr.time}: ${cr.message}');
  });
  hierarchicalLoggingEnabled = true;

  final runner =
      CommandRunner('jefe', 'Manages a set of related Dart projects');
  runner
    ..addCommand(Install())
    ..addCommand(Init())
    ..addCommand(Jefetise())
    ..addCommand(Start())
    ..addCommand(Finish())
    ..addCommand(Exec())
    ..addCommand(SetDependencies())
    ..addCommand(Test())
    ..addCommand(Release());

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

abstract class BaseJefeCommand extends Command {
  addGitUri() => argParser.addOption('gitUri',
      help: 'The git Uri containing the jefe.yaml.', abbr: 'g');

  addInstallDirectory() => argParser.addOption('installDirectory',
      help: 'The directory to install into', abbr: 'd', defaultsTo: '.');

  addContainerDirectory() => argParser.addOption('containerDirectory',
      help: 'The directory that contains the projects',
      abbr: 'd',
      defaultsTo: '.');

  addSkipCheckout() => argParser.addFlag('skipCheckout',
      help: 'Skips the checkout of the develop branch',
      abbr: 's',
      defaultsTo: false);

  addRootDirectory() => argParser.addOption('rootDirectory',
      help: 'The directory that contains the root of the projecs',
      abbr: 'd',
      defaultsTo: '.');

  addProjects() => argParser.addOption('projects',
      help:
          'A project name filter. Only projects whose name contains the text will run',
      abbr: 'p');

  String get gitUri => argResults['gitUri'];

  String get installDirectory => argResults['installDirectory'];

  String get containerDirectory => argResults['containerDirectory'];

  String get rootDirectory => argResults['rootDirectory'];

  bool get skipCheckout => argResults['skipCheckout'];

  String get projects => argResults['projects'];
}

class Install extends BaseJefeCommand {
  final name = "install";
  final description = "Installs a group of projects";

  Install() {
    addGitUri();
    addInstallDirectory();
  }

  Future run() {
    return install(gitUri, installDirectory: installDirectory);
  }

  Future install(String gitUri, {String installDirectory: '.'}) async {
    final Directory installDir = new Directory(installDirectory);
    final ProjectGroup projectGroup =
        await ProjectGroup.install(installDir, gitUri);

    await (await projectGroup.rootJefeProjects).lifecycle.init();
  }
}

class Jefetise extends BaseJefeCommand {
  final name = "jefetise";
  final description = 'Converts a directory of projects into a jefe group. '
      'WARNING renames the current directory to append _root to name';

  Jefetise() {
    addContainerDirectory();
  }

  Future run() {
    return jefetise(containerDirectory: containerDirectory);
  }

  Future jefetise({String containerDirectory: '.'}) async {
    final Directory parentDir = new Directory(containerDirectory);
    await ProjectGroup.jefetize(parentDir);
  }
}

class Init extends BaseJefeCommand {
  final name = "init";
  final description = 'Installs or updates a group of projects';

  Init() {
    addGitUri();
    addInstallDirectory();
    addSkipCheckout();
  }

  Future run() {
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

    await (await projectGroup.rootJefeProjects)
        .lifecycle
        .init(doCheckout: !skipCheckout);
  }
}

class Start extends BaseJefeCommand {
  final name = "start";
  final description = 'Sets up for the start of development on a new feature';

  Start() {
    argParser.addOption('featureName',
        help: 'The name of the feature to start', abbr: 'f');

    addRootDirectory();
    addProjects();
  }

  Future run() {
    final featureName = argResults['featureName'];
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

class Finish extends BaseJefeCommand {
  final name = "finish";
  final description = 'Completes feature and returns to development branch';

  Finish() {
    addRootDirectory();
    addProjects();
  }

  Future run() {
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

class Exec extends BaseJefeCommand {
  final name = "exec";
  final description = 'Runs the given command in all projects';

  Exec() {
    argParser.addOption('command', help: 'The command to execute', abbr: 'c');
    addRootDirectory();
    addProjects();
    argParser.addFlag('executeSerially',
        help:
            'Instead of running the commands concurrently on the projects, run only one command on one project at a time',
        abbr: 's',
        defaultsTo: false);
  }

  Future run() {
    final commandArgs = argResults.rest.toList();
    final command = argResults['command'];
    final executeSerially = argResults['executeSerially'];

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

class SetDependencies extends BaseJefeCommand {
  final name = "set-dependencies";
  final description = 'Set dependencies between projects';

  SetDependencies() {
    argParser.addOption('type',
        help: 'The type of dependency to set',
        abbr: 't',
        allowed: const ['git', 'path', 'hosted']);
    addRootDirectory();
    addProjects();
  }

  Future run() {
    final type = argResults['type'];
    return setDependencies(type,
        rootDirectory: rootDirectory, projects: projects);
  }

  setDependencies(String type,
      {String rootDirectory: '.', String projects}) async {
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
}

class Test extends BaseJefeCommand {
  final name = "test";
  final description = 'Runs tests projects that have tests';

  Test() {
    addRootDirectory();
    addProjects();
  }

  Future run() {
    return test(rootDirectory: rootDirectory, projects: projects);
  }

  test({String rootDirectory: '.', String projects}) async {
    final graph = await _loadGraph(rootDirectory);
    final pub = graph
        .multiProjectCommands(projectFilter: projectNameFilter(projects))
        .pub;

    return pub.test();
  }
}

class Release extends BaseJefeCommand {
  final name = "release";
  final description = 'Create a release of all the projects';

  Release() {
    addRootDirectory();
    addProjects();
    argParser.addOption('type',
        help: 'The type of release',
        abbr: 't',
        allowed: ReleaseType.all.map((r) => r.toString()),
        defaultsTo: ReleaseType.lowest.toString());
    argParser.addFlag('preReleaseOnly',
        help: 'if true then only pre release verification steps are executed',
        defaultsTo: false);
    argParser.addFlag('skipPreRelease',
        help: 'if true then the pre release verification steps are skipped',
        defaultsTo: false);
    argParser.addFlag('autoUpdateHostedVersions',
        help:
            'if true then version numbers of hosted packages will also be updated',
        defaultsTo: false);
  }

  Future run() {
    final type = _parseReleaseType(argResults['type']);
    final preReleaseOnly = argResults['preReleaseOnly'];
    final skipPreRelease = argResults['skipPreRelease'];
    final autoUpdateHostedVersions = argResults['autoUpdateHostedVersions'];
    return release(
        type: type,
        rootDirectory: rootDirectory,
        projects: projects,
        preReleaseOnly: preReleaseOnly,
        skipPreRelease: skipPreRelease,
        autoUpdateHostedVersions: autoUpdateHostedVersions);
  }

  release(
      {String rootDirectory: '.',
      String projects,
      ReleaseType type: ReleaseType.lowest,
      bool preReleaseOnly: false,
      bool skipPreRelease: false,
      autoUpdateHostedVersions: false}) async {
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
}

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

Future<JefeProjectGraph> _loadGraph(String rootDirectory) async =>
    await (await _load(rootDirectory)).rootJefeProjects;

Future<ProjectGroup> _load(String rootDirectory) async {
  final Directory installDir =
      rootDirectory == '.' ? Directory.current : new Directory(rootDirectory);
  return ProjectGroup.load(installDir);
}

ReleaseType _parseReleaseType(String str) => ReleaseType.fromLiteral(str).value;
