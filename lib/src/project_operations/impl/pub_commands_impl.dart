library jefe.project.operations.pub.impl;

import 'package:logging/logging.dart';
import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project_operations/project_command.dart';
import 'package:jefe/src/project_operations/pub_commands.dart';
import 'package:jefe/src/pub/pub.dart' as pub;

Logger _log = new Logger('jefe.project.operations.pub.impl');

class PubCommandsImpl implements PubCommands {
  @override
  ProjectCommand get() => projectCommand(
      'pub get', (Project p) async => await pub.get(p.installDirectory));
}
