library devops.project.operations.git;

import 'package:devops/src/project_operations/project_command.dart';

abstract class GitCommands {
  ProjectCommand commit(String message);

  ProjectCommand push();
}
