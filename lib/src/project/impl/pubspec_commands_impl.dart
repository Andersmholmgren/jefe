// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.pub.spec.impl;

import 'dart:async';

import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project/pubspec_commands.dart';
import 'package:jefe/src/project_commands/project_command.dart'
    show executeTask;
import 'package:jefe/src/pub/pub.dart' as pub;
import 'package:jefe/src/pub/pub_version.dart';
import 'package:logging/logging.dart';
import 'package:option/option.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec/pubspec.dart';

Logger _log = new Logger('jefe.project.commands.pub.impl');

class PubSpecCommandsImpl implements PubSpecCommands {
  final JefeProject _project;

  PubSpecCommandsImpl(this._project);

  @override
  Future setToPathDependencies() =>
      _setToDependenciesCommand(DependencyType.path, false);

  // Note: this must run serially
  @override
  Future setToGitDependencies() =>
      _setToDependenciesCommand(DependencyType.git, false);

  // Note: this must run serially
  @override
  Future setToHostedDependencies({bool useGitIfNotHosted: true}) =>
      _setToDependenciesCommand(DependencyType.hosted, useGitIfNotHosted);

  Future _setToDependenciesCommand(
      DependencyType type, bool useGitIfNotHosted) {
    return executeTask(
        'change to $type dependencies',
        () async => _project.processDepthFirst((JefeProject p) async {
              await _setToDependencies(
                  p, p.directDependencies, type, useGitIfNotHosted);
            }));
  }

  @override
  Future<bool> haveDependenciesChanged(DependencyType type,
      {bool useGitIfNotHosted: true}) {
    Future<bool> x(JefeProject p) => (p.pubspecCommands as PubSpecCommandsImpl)
        ._haveDependenciesChangedInThisProject(type, useGitIfNotHosted);

    return executeTask/*<bool>*/(
        'checking if $type dependencies have changed',
        () => _project.processDepthFirst/*<bool>*/(x,
            combine: (bool b1, bool b2) => b1 || b2));
  }

  Future<bool> _haveDependenciesChangedInThisProject(
      DependencyType type, bool useGitIfNotHosted) async {
    final exportedPackageNames = await _project.exportedPackageNames;

    final actualDependencies = _project.pubspec.allDependencies;

    final expectedDependencies = await _createDependencyReferences(
        _project,
        _project.directDependencies,
        actualDependencies,
        exportedPackageNames,
        type,
        useGitIfNotHosted);

    final dependenciesChanged = expectedDependencies.keys
        .any((k) => expectedDependencies[k] != actualDependencies[k]);

    _log.info('dependencies for ${_project.name} have '
        '${dependenciesChanged ? "" : "NOT "}changed');
    return dependenciesChanged;
  }

  Future _setToDependencies(Project project, Iterable<Project> dependencies,
      DependencyType type, bool useGitIfNotHosted) async {
    _log.info('Setting up $type dependencies for project ${project.name}');
    final exportedPackageNames = await project.exportedPackageNames;

    final newDependencies = await _createDependencyReferences(
        project,
        dependencies,
        project.pubspec.dependencies,
        exportedPackageNames,
        type,
        useGitIfNotHosted);

    final newDevDependencies = await _createDependencyReferences(
        project,
        dependencies,
        project.pubspec.devDependencies,
        exportedPackageNames,
        type,
        useGitIfNotHosted);

    final newPubspec = project.pubspec.copy(
        dependencies: newDependencies, devDependencies: newDevDependencies);

    await project.updatePubspec(newPubspec);
    _log.finer(
        'Finished setting up $type dependencies for project ${project.name}');
  }

  Future<Map<String, DependencyReference>> _createDependencyReferences(
      Project project,
      Iterable<Project> allDependencies,
      Map<String, DependencyReference> dependencyRefs,
      Set<String> exportedPackageNames,
      DependencyType type,
      bool useGitIfNotHosted) async {
    final newDependencies =
        new Map<String, DependencyReference>.from(dependencyRefs);

    final pubspecProjectNames = dependencyRefs.keys.toSet();

    final pubspecDependencies =
        allDependencies.where((p) => pubspecProjectNames.contains(p.name));

    await Future.wait(pubspecDependencies.map((p) async {
      final ref = await _createDependencyReference(
          p, type, useGitIfNotHosted, exportedPackageNames);
      _log.finest('created reference $ref to project ${p.name}');
      newDependencies[p.name] = ref;
    }));

    return newDependencies;
  }

  Future<DependencyReference> _createDependencyReference(
      Project project,
      DependencyType type,
      bool useGitIfNotHosted,
      Set<String> exportedDependencyNames) async {
    switch (type) {
      case DependencyType.path:
        return new PathReference(project.installDirectory.path);

      case DependencyType.git:
        return new GitReference(
            project.gitUri, await project.currentGitCommitHash);

      case DependencyType.hosted:
        return _getHostedReference(
            project, useGitIfNotHosted, exportedDependencyNames);

      default:
        throw new StateError('unsupported type $type');
    }
  }

  Future<DependencyReference> _getHostedReference(Project project,
      bool useGitIfNotHosted, Set<String> exportedDependencyNames) async {
    final Option<HostedPackageVersions> packageVersionsOpt =
        await pub.fetchPackageVersions(project.name,
            publishToUrl: project.pubspec.publishTo);

    if (packageVersionsOpt is Some) {
      final Version version = packageVersionsOpt.get().versions.last.version;
      final isExported = exportedDependencyNames.contains(project.name);
      final versionConstraint = isExported
          ? new VersionRange(
              min: version, max: version.nextPatch, includeMin: true)
          : new VersionConstraint.compatibleWith(version);
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
