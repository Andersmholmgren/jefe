library devops.project.operations.pub.spec.impl;

import 'package:logging/logging.dart';
import 'package:devops/src/project.dart';
import 'package:devops/src/project_operations/project_command.dart';
import 'package:devops/src/project_operations/pubspec_commands.dart';
import 'package:devops/src/pubspec/pubspec.dart';
import 'dart:async';
import 'package:devops/src/pubspec/dependency.dart';

Logger _log = new Logger('devops.project.operations.pub.impl');

class PubSpecCommandsImpl implements PubSpecCommands {
  @override
  ProjectCommand setToPathDependencies() => projectCommandWithDependencies(
      'change to path dependencies',
      (Project p, Iterable<Project> dependencies) async {
    await _setDependencies(p, 'path', dependencies, (Project p) =>
        new Future.value(new PathReference(p.installDirectory.path)));
  }, concurrencyMode: CommandConcurrencyMode.concurrentCommand);

  // Note: this must run serially
  @override
  ProjectCommand setToGitDependencies() => projectCommandWithDependencies(
      'change to path dependencies',
      (Project p, Iterable<Project> dependencies) async {
    await _setDependencies(p, 'git', dependencies, (Project p) async =>
        await new GitReference(p.gitUri, await p.currentGitCommitHash));
  });

  @override
  ProjectCommand update(PubSpec pubspec) => projectCommand(
      'update pubspec', (Project p) async => await p.updatePubspec(pubspec));
}

Future _setDependencies(Project project, String type,
    Iterable<Project> dependencies,
    Future<DependencyReference> createReferenceTo(Project p)) async {
  _log.info('Setting up $type dependencies for project ${project.name}');
  if (dependencies.isEmpty) {
    _log.finest('No depenencies for project ${project.name}');
    return;
  }

  final newDependencies = new Map.from(project.pubspec.dependencies);

  await Future.wait(dependencies.map((p) async {
    final ref = await createReferenceTo(p);
    _log.finest('created reference $ref for project ${project.name}');
    newDependencies[p.name] = ref;
  }));

  final newPubspec = project.pubspec.copy(dependencies: newDependencies);
  await project.updatePubspec(newPubspec);
  _log.finer(
      'Finished setting up $type dependencies for project ${project.name}');
}
