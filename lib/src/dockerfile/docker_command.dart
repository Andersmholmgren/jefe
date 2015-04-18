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
