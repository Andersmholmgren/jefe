library devops.project.operations.pub.spec;

import 'package:devops/src/project_operations/project_command.dart';
import 'package:devops/src/pubspec/pubspec.dart';

abstract class PubSpecCommands {
  // This doesn't need to be run serially
  ProjectCommand setToPathDependencies();

  // TODO: this must be serial
  ProjectCommand setToGitDependencies();

  ProjectCommand update(PubSpec pubspec);
}
