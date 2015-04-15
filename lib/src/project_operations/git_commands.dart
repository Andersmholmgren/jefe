library devops.project.operations.git;

import 'dart:async';

abstract class GitCommands {
  Future commit(String message);

  Future push();
}
