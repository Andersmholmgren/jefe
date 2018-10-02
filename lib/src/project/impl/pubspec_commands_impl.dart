// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.pub.spec.impl;

import 'dart:async';

import 'package:jefe/src/project/impl/multi_project_command_support.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project/pubspec_commands.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:jefe/src/pub/pub.dart' as pub;
import 'package:jefe/src/pub/pub_version.dart';
import 'package:logging/logging.dart';
import 'package:quiver/core.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec/pubspec.dart';

import 'package:path/path.dart' as p;

Logger _log = new Logger('jefe.project.commands.pubspec.impl');

PubSpecCommands createPubSpecCommands(JefeProjectGraph graph,
    {bool multiProject: true,
    CommandConcurrencyMode defaultConcurrencyMode,
    ProjectFilter projectFilter}) {
  return multiProject
      ? new PubSpecCommandsMultiProjectImpl(graph,
          defaultConcurrencyMode: defaultConcurrencyMode,
          projectFilter: projectFilter)
      : new PubSpecCommandsSingleProjectImpl(graph as JefeProject);
}

class PubSpecCommandsSingleProjectImpl
    extends SingleProjectCommandSupport<PubSpecCommands>
    implements PubSpecCommands {
  PubSpecCommandsSingleProjectImpl(JefeProject project)
      : super(
            (JefeProject p) async =>
                new _PubSpecCommandsSingleProjectImpl(project),
            project);

  @override
  Future addDependencyOn(Project dependee) =>
      doExecuteTask('addDependencyOn', (c) => c.addDependencyOn(dependee));

  @override
  Future<bool> haveDependenciesChanged(DependencyType type,
          {bool useGitIfNotHosted: true}) =>
      doExecuteTask(
          'haveDependenciesChanged',
          (c) => c.haveDependenciesChanged(type,
              useGitIfNotHosted: useGitIfNotHosted));

  @override
  Future setToGitDependencies() =>
      doExecuteTask('setToGitDependencies', (c) => c.setToGitDependencies());

  @override
  Future setToHostedDependencies(
          {bool useGitIfNotHosted: true}) =>
      doExecuteTask(
          'setToHostedDependencies',
          (c) =>
              c.setToHostedDependencies(useGitIfNotHosted: useGitIfNotHosted));

  @override
  Future setToPathDependencies() =>
      doExecuteTask('setToPathDependencies', (c) => c.setToPathDependencies());
}

class PubSpecCommandsMultiProjectImpl
    extends MultiProjectCommandSupport<PubSpecCommands>
    implements PubSpecCommands {
  PubSpecCommandsMultiProjectImpl(JefeProjectGraph graph,
      {CommandConcurrencyMode defaultConcurrencyMode,
      ProjectFilter projectFilter})
      : super(graph,
            (JefeProject p) async => new PubSpecCommandsSingleProjectImpl(p),
            defaultConcurrencyMode: defaultConcurrencyMode,
            projectFilter: projectFilter);

  @override
  Future<bool> haveDependenciesChanged(DependencyType type,
      {bool useGitIfNotHosted: true}) {
    return process<bool>(
        'have dependencies changed',
        (JefeProject p) async => p.pubspecCommands.haveDependenciesChanged(type,
            useGitIfNotHosted: useGitIfNotHosted),
        combine: (bool b1, bool b2) => b1 || b2,
        mode: CommandConcurrencyMode.serialDepthFirst);
  }
}

class _PubSpecCommandsSingleProjectImpl implements PubSpecCommands {
  final JefeProject _project;

  _PubSpecCommandsSingleProjectImpl(this._project);

  @override
  Future setToPathDependencies() =>
      _setToDependencies(DependencyType.path, false);

  // Note: this must run serially
  @override
  Future setToGitDependencies() =>
      _setToDependencies(DependencyType.git, false);

  // Note: this must run serially
  @override
  Future setToHostedDependencies({bool useGitIfNotHosted: true}) =>
      _setToDependencies(DependencyType.hosted, useGitIfNotHosted);

  @override
  Future<bool> haveDependenciesChanged(DependencyType type,
      {bool useGitIfNotHosted: true}) async {
    final exportedPackageNames = await _project.exportedPackageNames;

    final actualDependencies = _project.pubspec.allDependencies;

    final expectedDependencies = await _createDependencyReferences(
        actualDependencies, exportedPackageNames, type, useGitIfNotHosted);

    final dependenciesChanged = expectedDependencies.keys
        .any((k) => expectedDependencies[k] != actualDependencies[k]);

    _log.info('dependencies for ${_project.name} have '
        '${dependenciesChanged ? "" : "NOT "}changed');
    return dependenciesChanged;
  }

  Future _setToDependencies(DependencyType type, bool useGitIfNotHosted) async {
    _log.info('Setting up $type dependencies for project ${_project.name}');
    final exportedPackageNames = await _project.exportedPackageNames;

    final newDependencies = await _createDependencyReferences(
        _project.pubspec.dependencies,
        exportedPackageNames,
        type,
        useGitIfNotHosted);

    _log.finest(() => 'newDependencies: $newDependencies');

    final newDevDependencies = await _createDependencyReferences(
        _project.pubspec.devDependencies,
        exportedPackageNames,
        type,
        useGitIfNotHosted);

    final newPubspec = _project.pubspec.copy(
        dependencies: newDependencies, devDependencies: newDevDependencies);

    await _project.updatePubspec(newPubspec);
    _log.finer(
        'Finished setting up $type dependencies for project ${_project.name}');
  }

  Future<Map<String, DependencyReference>> _createDependencyReferences(
      Map<String, DependencyReference> dependencyRefs,
      Set<String> exportedPackageNames,
      DependencyType type,
      bool useGitIfNotHosted) async {
    final newDependencies =
        new Map<String, DependencyReference>.from(dependencyRefs);

    final pubspecProjectNames = dependencyRefs.keys.toSet();

    final pubspecDependencies = _project.directDependencies
        .where((p) => pubspecProjectNames.contains(p.name));

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
        return new PathReference(p.relative(project.installDirectory.path,
            from: _project.installDirectory.path));

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
    final Optional<HostedPackageVersions> packageVersionsOpt =
        await pub.fetchPackageVersions(project.name,
            publishToUrl: project.pubspec.publishTo);

    if (packageVersionsOpt.isPresent) {
      final Version version = packageVersionsOpt.value.versions.last.version;
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

  @override
  Future addDependencyOn(Project dependee) async {
    final names = _project.directDependencies.map((p) => p.name);
    final deps = _project.pubspec.dependencies;
    final projectDependencyRefs = names.map((name) => deps[name]);

    final projectDependencyTypes =
        projectDependencyRefs.map((pd) => pd.runtimeType).toSet();

    DependencyType determineDependencyType() {
      switch (projectDependencyTypes.length) {
        case 0:
          return DependencyType.path;
        case 1:
          return DependencyType.values
              .firstWhere((t) => t.runtimeType == projectDependencyTypes.first);
        default:
          throw new StateError(
              "can't infer dependency type as there is a mixture of types "
              "(${projectDependencyTypes}) used in the project (${_project.name})");
      }
    }

    final dependencyType = determineDependencyType();

    final newDependencyReference = await _createDependencyReference(dependee,
        dependencyType, true, (await _project.exportedDependencyNames).toSet());

    final newDependencies = <String, DependencyReference>{}
      ..addAll(_project.pubspec.dependencies)
      ..addAll({dependee.name: newDependencyReference});

    final newPubspec = _project.pubspec.copy(dependencies: newDependencies);

    await _project.updatePubspec(newPubspec);
  }
}
