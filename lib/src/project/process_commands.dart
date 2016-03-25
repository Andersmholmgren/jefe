// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.process;

import 'dart:async';
import 'dart:io';
import 'package:jefe/src/project/project.dart';
import 'package:stuff/stuff.dart';
import 'dart:convert';

abstract class ProcessCommands {
  /// Invokes the provided command with the projects directory as the processes
  /// working directory
  Future<Iterable<ProcessCommandResult>> execute(
      String command, List<String> args);
}

class ProcessCommandResult {
  final ProcessResult result;
  final Project project;

  ProcessCommandResult(this.result, this.project);

  Map toJson() => (buildJson
        ..add('projectName', project.name)
        ..add('exitCode', result.exitCode)
        ..add('stdout', _trimToNull(result.stdout))
        ..add('stderr', _trimToNull(result.stderr)))
      .json;

  String toString() => JSON.encode(this);

  String toReportString() {
    final sb = new StringBuffer()
      ..writeln(project.name)
      ..writeln((new List.generate(project.name.length, (_) => '-')
          .reduce((v, e) => v + e)));
    if (result.exitCode == 0) {
      sb.writeln(result.stdout.trim());
    } else {
      sb
        ..writeln('exitCode: ${result.exitCode}')
        ..writeln(result.stderr.trim());
    }
    return sb.toString();
  }
}

String _trimToNull(String s) {
  if (s == null) {
    return s;
  }
  final s1 = s.trim();
  return s1.isEmpty ? null : s1;
}
