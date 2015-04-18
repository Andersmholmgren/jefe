library devops.project.operations.pub;

import 'package:devops/src/project_operations/project_command.dart';
import 'impl/pub_commands_impl.dart';

abstract class PubCommands {
  factory PubCommands() = PubCommandsImpl;
  ProjectCommand get();
}
