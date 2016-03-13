// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.process;

import 'dart:async';

abstract class ProcessCommands {
  /// Invokes the provided command with the projects directory as the processes
  /// working directory
  Future execute(String command, List<String> args);
}
