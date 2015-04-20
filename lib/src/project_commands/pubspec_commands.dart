// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.pub.spec;

import 'package:jefe/src/project_commands/project_command.dart';
import 'impl/pubspec_commands_impl.dart';
import 'package:pubspec/pubspec.dart';

abstract class PubSpecCommands {
  factory PubSpecCommands() = PubSpecCommandsImpl;

  ProjectCommand setToPathDependencies();

  ProjectCommand setToGitDependencies();

  ProjectCommand update(PubSpec pubspec);
}
