library devops.utils;

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
