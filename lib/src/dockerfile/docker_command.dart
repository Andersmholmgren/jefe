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

class _BaseRunCommand extends DockerCommand {
  final String name;
  final String command;
  final Iterable<String> args;
  final bool execForm;

  _BaseRunCommand(this.name, this.command, this.args, this.execForm);

  @override
  void write(IOSink sink) {
    if (execForm) {
      final list = _formatList(concat([[command], args]));
      sink.writeln('$name $list');
    } else {
      sink.writeln('$name $command ${args.join(' ')}');
    }
  }
}

class RunCommand extends _BaseRunCommand {
  RunCommand(String command, Iterable<String> args, bool execForm)
      : super('RUN', command, args, execForm);
}

class EntryPointCommand extends _BaseRunCommand {
  EntryPointCommand(String command, Iterable<String> args, bool execForm)
      : super('ENTRYPOINT', command, args, execForm);
}

String _formatList(Iterable<String> list) {
  final l = list.map((i) => '"$i"').join(', ');
  return '[$l]';
}
