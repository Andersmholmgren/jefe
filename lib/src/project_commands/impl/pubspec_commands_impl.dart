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
  ProjectCommand setToPathDependencies() =>
      _setToDependenciesCommand(DependencyType.path, false);

  // Note: this must run serially
  @override
  ProjectCommand setToGitDependencies() =>
      _setToDependenciesCommand(DependencyType.git, false);

  // Note: this must run serially
  @override
  ProjectCommand setToHostedDependencies({bool useGitIfNotHosted: true}) =>
      _setToDependenciesCommand(DependencyType.hosted, useGitIfNotHosted);

  ProjectCommand _setToDependenciesCommand(
          DependencyType type, bool useGitIfNotHosted) =>
      projectCommandWithDependencies('change to $type dependencies',
          (Project p, Iterable<Project> dependencies) async {
    await _setToDependencies(p, dependencies, type, useGitIfNotHosted);
  });

  @override
  ProjectCommand<bool> haveDependenciesChanged(DependencyType type,
      {bool useGitIfNotHosted: true}) => projectCommandWithDependencies(
          'checking if $type dependencies have changed',
          (Project project, Iterable<Project> dependencies) async {
    final expectedDependencies = await _createDependencyReferences(
        project, dependencies, type, useGitIfNotHosted);

    final actualDependencies = project.pubspec.dependencies;

    final dependenciesChanged = expectedDependencies.keys
        .any((k) => expectedDependencies[k] != actualDependencies[k]);

    _log.info('dependencies for ${project.name} have '
        '${dependenciesChanged ? "" : "NOT "}changed');
    return dependenciesChanged;
  });

  Future _setToDependencies(Project project, Iterable<Project> dependencies,
      DependencyType type, bool useGitIfNotHosted) async {
    _log.info('Setting up $type dependencies for project ${project.name}');
    final newDependencies = await _createDependencyReferences(
        project, dependencies, type, useGitIfNotHosted);

    final newPubspec = project.pubspec.copy(dependencies: newDependencies);
    await project.updatePubspec(newPubspec);
    _log.finer(
        'Finished setting up $type dependencies for project ${project.name}');
  }

  Future<Map<String, DependencyReference>> _createDependencyReferences(
      Project project, Iterable<Project> dependencies, DependencyType type,
      bool useGitIfNotHosted) async {
    if (dependencies.isEmpty) {
      _log.finest('No depenencies for project ${project.name}');
      return await const {};
    }

    final newDependencies = new Map.from(project.pubspec.dependencies);

    await Future.wait(dependencies.map((p) async {
      final ref = await _createDependencyReference(p, type, useGitIfNotHosted);
      _log.finest('created reference $ref for project ${project.name}');
      newDependencies[p.name] = ref;
    }));

    return newDependencies;
  }

  Future<DependencyReference> _createDependencyReference(
      Project project, DependencyType type, bool useGitIfNotHosted) async {
    switch (type) {
      case DependencyType.path:
        return new PathReference(project.installDirectory.path);

      case DependencyType.git:
        return new GitReference(
            project.gitUri, await project.currentGitCommitHash);

      case DependencyType.hosted:
        return _getHostedReference(project, useGitIfNotHosted);

      default:
        throw new StateError('unsupported type $type');
    }
  }

  Future<DependencyReference> _getHostedReference(
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
}
