library devops.project.operations.process;

import 'package:devops/src/project_operations/project_command.dart';
import 'impl/git_commands_impl.dart';

abstract class ProcessCommands {
//  factory GitCommands() = GitCommandsImpl;

  ProjectCommand process(String command, List<String> args);
}
