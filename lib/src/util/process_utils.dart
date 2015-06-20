// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.utils;

import 'dart:async';
import 'dart:io';

int _processCount = 0;

Future<ProcessResult> runCommand(String command, List<String> args,
    {bool throwOnError: true, String processWorkingDir}) async {
  _processCount++;
  print('---- num running processes: $_processCount');

  final result =
      await Process.run(command, args, workingDirectory: processWorkingDir);

  _processCount--;

  if (throwOnError) {
    _throwIfProcessFailed(result, command, args);
  }
  return result;
}

void _throwIfProcessFailed(
    ProcessResult pr, String process, List<String> args) {
  assert(pr != null);
  if (pr.exitCode != 0) {
    var message = '''
stdout:
${pr.stdout}
stderr:
${pr.stderr}''';

    throw new ProcessException(process, args, message, pr.exitCode);
  }
}
