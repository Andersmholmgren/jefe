// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.process;

import 'package:jefe/src/project_commands/project_command.dart';
import 'impl/process_commands_impl.dart';

abstract class ProcessCommands {
  factory ProcessCommands() = ProcessCommandsImpl;

  /// Invokes the provided command with the projects directory as the processes
  /// working directory
  ProjectCommand process(String command, List<String> args);
}
