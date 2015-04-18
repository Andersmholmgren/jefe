import 'dart:io';
import 'package:quiver/iterables.dart';

abstract class DockerCommand {
  void write(IOSink sink);
}

class AddCommand extends _BaseCommandWithExecForm {
  final String from;
  final String to;

  AddCommand(this.from, this.to, bool execForm) : super('ADD', execForm);

  @override
  Iterable<String> get commandArgs => [from, to];
}

class WorkDirCommand extends DockerCommand {
  final String dir;

  WorkDirCommand(this.dir);

  @override
  void write(IOSink sink) {
    sink.writeln('WORKDIR $dir');
  }
}

class ExposeCommand extends DockerCommand {
  final Iterable<int> ports;

  ExposeCommand(this.ports);

  @override
  void write(IOSink sink) {
    sink.writeln('EXPOSE ${ports.join(', ')}');
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

abstract class _BaseCommandWithExecForm extends DockerCommand {
  final String name;
  Iterable<String> get commandArgs;
  final bool execForm;

  _BaseCommandWithExecForm(this.name, this.execForm);

  @override
  void write(IOSink sink) {
    if (execForm) {
      final list = _formatList(commandArgs);
      sink.writeln('$name $list');
    } else {
      sink.writeln('$name ${commandArgs.join(' ')}');
    }
  }
}

class _BaseRunCommand extends _BaseCommandWithExecForm {
  final String command;
  final Iterable<String> args;

  _BaseRunCommand(String name, this.command, this.args, bool execForm)
      : super(name, execForm);

  @override
  Iterable<String> get commandArgs => concat([[command], args]);
}

String _formatList(Iterable<String> list) {
  final l = list.map((i) => '"$i"').join(', ');
  return '[$l]';
}
