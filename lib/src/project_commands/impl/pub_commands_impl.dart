// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.pub.impl;

import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:jefe/src/project_commands/pub_commands.dart';
import 'package:jefe/src/pub/pub.dart' as pub;
import 'package:logging/logging.dart';

Logger _log = new Logger('jefe.project.commands.pub.impl');

class PubCommandsImpl implements PubCommands {
  @override
  ProjectCommand get() => projectCommand(
      'pub get', (Project p) async => await pub.get(p.installDirectory));

  @override
  ProjectCommand fetchPackageVersions() => projectCommand(
      'fetch package versions', (Project p) => p.publishedVersions);

  @override
  ProjectCommand publish() => projectCommand('pub publish',
      (Project p) async => await pub.publish(p.installDirectory));

  @override
  ProjectCommand test() => projectCommand('pub run test', (Project p) async {
        final hasTestPackage = p.pubspec.allDependencies.containsKey('test');
        if (hasTestPackage) {
          return await pub.test(p.installDirectory);
        } else {
          _log.warning(() =>
              "Ignoring tests for project ${p.name} as doesn't use test package");
        }
      });
}
