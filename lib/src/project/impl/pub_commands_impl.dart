// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.pub.impl;

import 'dart:async';

import 'package:jefe/src/project/impl/multi_project_command_support.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project/pub_commands.dart';
import 'package:jefe/src/project_commands/project_command.dart'
    show CommandConcurrencyMode, executeTask;
import 'package:jefe/src/pub/pub.dart' as pub;
import 'package:logging/logging.dart';

Logger _log = new Logger('jefe.project.commands.pub.impl');

PubCommands createPubCommands(JefeProjectGraph graph,
    {bool multiProject: true,
    CommandConcurrencyMode defaultConcurrencyMode,
    ProjectFilter projectFilter}) {
  return multiProject
      ? new PubCommandsMultiProjectImpl(graph,
          defaultConcurrencyMode: defaultConcurrencyMode,
          projectFilter: projectFilter)
      : new PubCommandsSingleProjectImpl(graph as JefeProject);
}

class PubCommandsSingleProjectImpl
    extends SingleProjectCommandSupport<PubCommands> implements PubCommands {
  PubCommandsSingleProjectImpl(JefeProject project)
      : super(
            (JefeProject p) async => new _PubCommandsSingleProjectImpl(project),
            project);
}

class PubCommandsMultiProjectImpl
    extends MultiProjectCommandSupport<PubCommands> implements PubCommands {
  PubCommandsMultiProjectImpl(JefeProjectGraph graph,
      {CommandConcurrencyMode defaultConcurrencyMode,
      ProjectFilter projectFilter})
      : super(
            graph, (JefeProject p) async => new PubCommandsSingleProjectImpl(p),
            defaultConcurrencyMode: defaultConcurrencyMode,
            projectFilter: projectFilter);
}

class _PubCommandsSingleProjectImpl implements PubCommands {
  final JefeProject _project;
  _PubCommandsSingleProjectImpl(this._project);

  @override
  Future get() =>
      executeTask('pub get', () async => pub.get(_project.installDirectory));

  @override
  Future fetchPackageVersions() =>
      executeTask('fetch package versions', () => _project.publishedVersions);

  @override
  Future publish() => executeTask(
      'pub publish', () async => pub.publish(_project.installDirectory));

  @override
  Future test() => executeTask('pub run test', () async {
        final hasTestPackage =
            _project.pubspec.allDependencies.containsKey('test');
        if (hasTestPackage) {
          return await pub.test(_project.installDirectory);
        } else {
          _log.warning(() =>
              "Ignoring tests for project ${_project.name} as doesn't use test package");
        }
      });
}
