library devops.project.operations.pub.impl;

import 'package:logging/logging.dart';
import 'package:devops/src/project/project.dart';
import 'package:devops/src/project_operations/project_command.dart';
import 'package:devops/src/project_operations/pub_commands.dart';
import 'package:devops/src/pub/pub.dart' as pub;

Logger _log = new Logger('devops.project.operations.pub.impl');

class PubCommandsImpl implements PubCommands {
  @override
  ProjectCommand get() => projectCommand(
      'pub get', (Project p) async => await pub.get(p.installDirectory));
}
