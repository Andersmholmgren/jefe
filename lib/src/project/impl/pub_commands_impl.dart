// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.pub.impl;

import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project_commands/project_command.dart' show executeTask;
import 'package:jefe/src/pub/pub.dart' as pub;
import 'package:logging/logging.dart';
import 'dart:async';
import 'package:jefe/src/project/pub_commands.dart';
import 'package:jefe/src/project/jefe_project.dart';

Logger _log = new Logger('jefe.project.commands.pub.impl');

class PubCommandsImpl implements PubCommands {
  final JefeProject _project;
  PubCommandsImpl(this._project);

  @override
  Future get() => executeTask(
      'pub get', (Project p) async => await pub.get(p.installDirectory));

  @override
  Future fetchPackageVersions() => executeTask(
      'fetch package versions', (Project p) => p.publishedVersions);

  @override
  Future publish() => executeTask('pub publish',
      (Project p) async => await pub.publish(p.installDirectory));

  @override
  Future test() => executeTask('pub run test', (Project p) async {
        final hasTestPackage = p.pubspec.allDependencies.containsKey('test');
        if (hasTestPackage) {
          return await pub.test(p.installDirectory);
        } else {
          _log.warning(() =>
              "Ignoring tests for project ${p.name} as doesn't use test package");
        }
      });
}
