import 'dart:io';
import 'package:quiver/iterables.dart';

abstract class DockerCommand {
  void write(IOSink sink);
}

class AddCommand extends DockerCommand {
  final String from;
  final String to;

  AddCommand(this.from, this.to);

  @override
  void write(IOSink sink) {
    sink.writeln('ADD ${_formatList([from, to])}');
  }
}

class WorkDirCommand extends DockerCommand {
  final String dir;

  WorkDirCommand(this.dir);

  @override
  void write(IOSink sink) {
    sink.writeln('WORKDIR $dir');
  }
}

class RunCommand extends DockerCommand {
  final String command;
  final Iterable<String> args;
  final bool execForm;

  RunCommand(this.command, this.args, this.execForm);

  @override
  void write(IOSink sink) {
    if (execForm) {
      final list = _formatList(concat([[command], args]));
      sink.writeln('RUN $list');
    } else {
      sink.writeln('RUN $command ${args.join(' ')}');
    }
  }
}

String _formatList(Iterable<String> list) {
  final l = list.map((i) => '"$i"').join(', ');
  return '[$l]';
}
