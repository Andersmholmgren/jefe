// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.git;

import 'package:jefe/src/project_commands/project_command.dart';

import 'impl/git_commands_impl.dart';

abstract class GitCommands {
  factory GitCommands() = GitCommandsImpl;

  ProjectCommand commit(String message);

  ProjectCommand push();

  ProjectCommand fetch();

  ProjectCommand merge(String commit);

  ProjectCommand updateFromRemote(String branchName,
      [String remoteName = 'origin']);

  ProjectCommand assertWorkingTreeClean();

  ProjectCommand assertOnBranch(String branchName);

  ProjectCommand checkout(String branchName);
}
