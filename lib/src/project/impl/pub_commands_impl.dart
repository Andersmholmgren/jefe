// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.pub.impl;

import 'dart:async';

import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project/pub_commands.dart';
import 'package:jefe/src/project_commands/project_command.dart'
    show executeTask;
import 'package:jefe/src/pub/pub.dart' as pub;
import 'package:logging/logging.dart';

Logger _log = new Logger('jefe.project.commands.pub.impl');

abstract class PubCommandsImpl implements PubCommands {
  factory PubCommandsImpl(JefeProjectGraph graph, {bool multiProject: true}) {
    return multiProject
        ? new PubCommandsMultiProjectImpl(graph)
        : new PubCommandsSingleProjectImpl(graph as JefeProject);
  }
}

class PubCommandsSingleProjectImpl
    extends SingleProjectCommandSupport<PubCommands> implements PubCommands {
  PubCommandsSingleProjectImpl(JefeProject project)
      : super(
            (JefeProject p) async =>
                new _PubCommandsSingleProjectImpl(project, await p.pubDir),
            project);
}

class PubCommandsMultiProjectImpl
    extends MultiProjectCommandSupport<PubCommands> implements PubCommands {
  PubCommandsMultiProjectImpl(JefeProjectGraph graph)
      : super(graph,
            (JefeProject p) async => new PubCommandsSingleProjectImpl(p));
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
