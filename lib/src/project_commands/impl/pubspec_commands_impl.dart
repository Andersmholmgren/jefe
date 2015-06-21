// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.pub.spec.impl;

import 'package:logging/logging.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:jefe/src/project_commands/pubspec_commands.dart';
import 'dart:async';
import 'package:pubspec/pubspec.dart';
import 'package:jefe/src/project_commands/pub_commands.dart';
import 'package:jefe/src/pub/pub.dart' as pub;
import 'package:option/option.dart';
import 'package:jefe/src/pub/pub_version.dart';
import 'package:pub_semver/pub_semver.dart';

Logger _log = new Logger('jefe.project.commands.pub.impl');

class PubSpecCommandsImpl implements PubSpecCommands {
  final PubCommands _pub;

  PubSpecCommandsImpl() : this._pub = new PubCommands();

  @override
  ProjectCommand setToPathDependencies() => _setToDependencies('path',
      (Project p) =>
          new Future.value(new PathReference(p.installDirectory.path)));

  // Note: this must run serially
  @override
  ProjectCommand setToGitDependencies() => _setToDependencies('git',
      (Project p) async =>
          await new GitReference(p.gitUri, await p.currentGitCommitHash));

  // Note: this must run serially
  @override
  ProjectCommand setToHostedDependencies({bool useGitIfNotHosted: true}) =>
      _setToDependencies('hosted',
          (Project p) async => getHostedReference(p, useGitIfNotHosted));

  Future<DependencyReference> getHostedReference(
      Project project, bool useGitIfNotHosted) async {
    final Option<HostedPackageVersions> packageVersionsOpt =
        await pub.fetchPackageVersions(project.name);
    if (packageVersionsOpt is Some) {
      final Version version = packageVersionsOpt.get().versions.last.version;
      final versionConstraint = new VersionConstraint.compatibleWith(version);
      return await new HostedReference(versionConstraint);
    } else if (useGitIfNotHosted) {
      return await new GitReference(
          project.gitUri, await project.currentGitCommitHash);
    } else {
      throw new ArgumentError(
          'attempt to create hosted dependency for package not hosted on pub');
    }
  }

  ProjectCommand _setToDependencies(String type,
          Future<DependencyReference> createReferenceTo(Project p)) =>
      projectCommandWithDependencies('change to $type dependencies',
          (Project p, Iterable<Project> dependencies) async {
    await _setDependencies(p, type, dependencies, createReferenceTo);
  });
}

Future _setDependencies(Project project, String type,
    Iterable<Project> dependencies,
    Future<DependencyReference> createReferenceTo(Project p)) async {
  _log.info('Setting up $type dependencies for project ${project.name}');
  final newDependencies = await _getDependenciesAsType(
      project, type, dependencies, createReferenceTo);

  final newPubspec = project.pubspec.copy(dependencies: newDependencies);
  await project.updatePubspec(newPubspec);
  _log.finer(
      'Finished setting up $type dependencies for project ${project.name}');
}

Future<Map<String, DependencyReference>> _getDependenciesAsType(Project project,
    String type, Iterable<Project> dependencies,
    Future<DependencyReference> createReferenceTo(Project p)) async {
  if (dependencies.isEmpty) {
    _log.finest('No depenencies for project ${project.name}');
    return await const {};
  }

  final newDependencies = new Map.from(project.pubspec.dependencies);

  await Future.wait(dependencies.map((p) async {
    final ref = await createReferenceTo(p);
    _log.finest('created reference $ref for project ${project.name}');
    newDependencies[p.name] = ref;
  }));

  return newDependencies;
}
