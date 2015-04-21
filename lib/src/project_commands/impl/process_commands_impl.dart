// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.process.impl;

import 'package:logging/logging.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:jefe/src/project_commands/process_commands.dart';
import 'package:jefe/src/util/process_utils.dart';

Logger _log = new Logger('jefe.project.commands.process.impl');

class ProcessCommandsImpl implements ProcessCommands {
  @override
  ProjectCommand process(String command, List<String> args) => projectCommand(
      command, (Project p) async => (await runCommand(command, args,
          processWorkingDir: p.installDirectory.path)).stdout.trim());
}
