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
  ProjectCommand setToPathDependencies() => projectCommandWithDependencies(
      'change to path dependencies',
      (Project p, Iterable<Project> dependencies) async {
        await _setDependencies(
            p,
            'path',
            dependencies,
            (Project p) =>
                new Future.value(new PathReference(p.installDirectory.path)));
      },
      concurrencyMode: CommandConcurrencyMode.concurrentCommand);

  // Note: this must run serially
  @override
  ProjectCommand setToGitDependencies() => projectCommandWithDependencies(
          'change to git dependencies',
          (Project p, Iterable<Project> dependencies) async {
        await _setDependencies(
            p,
            'git',
            dependencies,
            (Project p) async =>
                await new GitReference(p.gitUri, await p.currentGitCommitHash));
      });

  // Note: this must run serially
  @override
  ProjectCommand setToHostedDependencies({bool useGitIfNotHosted: true}) =>
      projectCommandWithDependencies('change to hosted dependencies',
          (Project project, Iterable<Project> dependencies) async {
        await _setDependencies(
            project, 'hosted', dependencies, (Project p) async {
          final Option<HostedPackageVersions> packageVersionsOpt =
              await pub.fetchPackageVersions(p.name);
          if (packageVersionsOpt is Some) {
            final Version version =
                packageVersionsOpt.get().versions.last.version;
            final versionConstraint =
                new VersionConstraint.compatibleWith(version);
            return await new HostedReference(versionConstraint);
          } else if (useGitIfNotHosted) {
            return await new GitReference(
                p.gitUri, await p.currentGitCommitHash);
          } else {
            throw new ArgumentError(
                'attempt to set to hosted dependency for package not hosted on pub');
          }
        });
      });
}

Future _setDependencies(
    Project project,
    String type,
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
