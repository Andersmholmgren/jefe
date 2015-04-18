import 'dart:io';

abstract class DockerCommand {
  void write(IOSink sink);
}

class AddCommand extends DockerCommand {
  final String from;
  final String to;

  AddCommand(this.from, this.to);

  @override
  void write(IOSink sink) {
    sink.writeln('ADD $from $to');
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

  RunCommand(this.command, this.args);

  @override
  void write(IOSink sink) {
    sink.writeln('RUN $command ${args.join(' ')}');
  }
}
