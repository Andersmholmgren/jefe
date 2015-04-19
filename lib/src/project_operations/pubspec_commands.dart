library devops.project.operations.pub.spec;

import 'package:devops/src/project_operations/project_command.dart';
import 'impl/pubspec_commands_impl.dart';
import 'package:pubspec/pubspec.dart';

abstract class PubSpecCommands {
  factory PubSpecCommands() = PubSpecCommandsImpl;

  ProjectCommand setToPathDependencies();

  ProjectCommand setToGitDependencies();

  ProjectCommand update(PubSpec pubspec);
}
