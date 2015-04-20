library jefe.project.operations.pub;

import 'package:jefe/src/project_operations/project_command.dart';
import 'impl/pub_commands_impl.dart';

abstract class PubCommands {
  factory PubCommands() = PubCommandsImpl;
  ProjectCommand get();
}
