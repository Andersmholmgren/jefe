library devops.project.operations.pub.spec;

import 'package:devops/src/project_operations/project_command.dart';

abstract class PubSpecCommands {
  // This doesn't need to be run serially
  ProjectCommand<ProjectWithDependenciesFunction> setToPathDependencies();

  // TODO: this must be serial
  ProjectCommand<ProjectWithDependenciesFunction> setToGitDependencies();
}
