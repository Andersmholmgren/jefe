// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.utils;

import 'dart:async';
import 'dart:io';

Future<ProcessResult> runCommand(String command, List<String> args,
    {bool throwOnError: true, String processWorkingDir}) {
  return Process
      .run(command, args, workingDirectory: processWorkingDir)
      .then((ProcessResult pr) {
    if (throwOnError) {
      _throwIfProcessFailed(pr, command, args);
    }
    return pr;
  });
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
