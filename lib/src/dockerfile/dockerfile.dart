library dockerfile.spec;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:devops/src/dockerfile/docker_command.dart';

const String _standardFileName = 'Dockerfile';

class Dockerfile {
  final List<DockerCommand> _commands = [];

//  static Future<Dockerfile> load(Directory projectDirectory) async =>
//      new Dockerfile.fromJson(loadYaml(
//          await new File(p.join(projectDirectory.path, _standardFileName))
//              .readAsString()));

  void add(String from, String to) {
    _commands.add(new AddCommand(from, to));
  }

  void write(IOSink sink) {
    _commands.forEach((c) {
      c.write(sink);
    });
  }

  Future save(Directory parentDir) {
    final ioSink =
        new File(p.join(parentDir.path, _standardFileName)).openWrite();
    try {
      write(ioSink);
    } finally {
      return ioSink.close();
    }
  }
}
