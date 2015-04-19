library devops.project.operations.process.impl;

import 'package:logging/logging.dart';
import 'package:devops/src/project/project.dart';
import 'package:devops/src/project_operations/project_command.dart';
import 'package:devops/src/project_operations/process_commands.dart';
import 'package:devops/src/util/process_utils.dart';

Logger _log = new Logger('devops.project.operations.process.impl');

class ProcessCommandsImpl implements ProcessCommands {
  @override
  ProjectCommand process(String command, List<String> args) => projectCommand(
      command, (Project p) async => await runCommand(command, args,
          processWorkingDir: p.installDirectory.toString()));
}
