library devops.project.operations.git;

import 'package:devops/src/project_operations/project_command.dart';

abstract class GitCommands {
  ProjectCommand<ProjectFunction> commit(String message);

  ProjectCommand<ProjectFunction> push();
}
