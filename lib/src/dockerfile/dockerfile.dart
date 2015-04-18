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

  void addDir(String from, String to) {
    final toDir = to.endsWith('/') ? to : to + '/';
    add(from, toDir);
  }

  void workDir(String dir) {
    _commands.add(new WorkDirCommand(dir));
  }

  void run(String command,
      {Iterable<String> args: const [], bool execForm: false}) {
    _commands.add(new RunCommand(command, args, execForm));
  }

  void entryPoint(String command,
      {Iterable<String> args: const [], bool execForm: true}) {
    _commands.add(new EntryPointCommand(command, args, execForm));
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
