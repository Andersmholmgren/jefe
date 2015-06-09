// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.pub;

import 'package:jefe/src/project_commands/project_command.dart';
import 'impl/pub_commands_impl.dart';

abstract class PubCommands {
  factory PubCommands() = PubCommandsImpl;

  ProjectCommand get();

  ProjectCommand hostedDetails();
}
