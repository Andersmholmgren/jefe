library jefe.project.operations.process;

import 'package:jefe/src/project_operations/project_command.dart';
import 'impl/process_commands_impl.dart';

abstract class ProcessCommands {
  factory ProcessCommands() = ProcessCommandsImpl;

  /// Invokes the provided command with the projects directory as the processes
  /// working directory
  ProjectCommand process(String command, List<String> args);
}
