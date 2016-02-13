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

class PubCommandsImpl implements PubCommands {
  final JefeProjectGraph _graph;
  PubCommandsImpl(this._graph);

  @override
  Future get() =>
      executeTask('pub get', () async => pub.get(_graph.installDirectory));

  @override
  Future fetchPackageVersions() =>
      executeTask('fetch package versions', () => _graph.publishedVersions);

  @override
  Future publish() => executeTask(
      'pub publish', () async => pub.publish(_graph.installDirectory));

  @override
  Future test() => executeTask('pub run test', () async {
        final hasTestPackage =
            _graph.pubspec.allDependencies.containsKey('test');
        if (hasTestPackage) {
          return await pub.test(_graph.installDirectory);
        } else {
          _log.warning(() =>
              "Ignoring tests for project ${_graph.name} as doesn't use test package");
        }
      });
}
