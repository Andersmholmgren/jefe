import 'dart:io';
import 'package:quiver/iterables.dart';

abstract class DockerCommand {
  void write(IOSink sink);
}

//FROM google/dart:1.9.1

class FromCommand extends DockerCommand {
  final String image;
  final String tag;
  final String digest;

  FromCommand(this.image, this.tag, this.digest) {
    if (tag != null && digest != null) {
      throw new ArgumentError('only one of tag and digest can be specified');
    }
  }

  @override
  void write(IOSink sink) {
    final String ref =
        tag != null ? '$image:$tag' : digest != null ? '$image@$digest' : image;

    sink.writeln('FROM $ref');
  }
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

class ExposeCommand extends _BaseCommandWithExecForm {
  final Iterable<int> ports;

  ExposeCommand(this.ports) : super('EXPOSE', false);

  @override
  Iterable get commandArgs => ports;
}

class EnvCommand extends _BaseCommandWithExecForm {
  final String key;
  final value;

  EnvCommand(this.key, this.value) : super('ENV', false);

  @override
  Iterable get commandArgs => [key, value];
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
  Iterable get commandArgs;
  final bool execForm;

  _BaseCommandWithExecForm(this.name, this.execForm);

  @override
  void write(IOSink sink) {
    if (commandArgs.isNotEmpty) {
      if (execForm) {
        final list = _formatList(commandArgs);
        sink.writeln('$name $list');
      } else {
        sink.writeln('$name ${commandArgs.join(' ')}');
      }
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
