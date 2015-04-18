library devops.project.operations.git.impl;

import 'package:devops/src/git/git.dart';
import 'package:logging/logging.dart';
import 'package:devops/src/project.dart';
import 'package:devops/src/project_operations/project_command.dart';
import 'package:devops/src/project_operations/git_commands.dart';

Logger _log = new Logger('devops.project.operations.git.impl');

class GitCommandsImpl implements GitCommands {
  @override
  ProjectCommand commit(String message) => projectCommand('git commit',
      (Project p) async {
    await gitCommit(await p.gitDir, message);
  });

  @override
  ProjectCommand push() => projectCommand('git push', (Project p) async {
    await gitPush(await p.gitDir);
  });
}
