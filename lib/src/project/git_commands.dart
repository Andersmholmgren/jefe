// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.git;

import 'dart:async';

import 'package:jefe/src/project/jefe_project.dart';
import 'package:pub_semver/pub_semver.dart';

abstract class GitCommands extends JefeGroupCommand<GitCommands> {
  Future commit(String message);

  Future push();

  Future fetch();

  Future merge(String commit);

  Future updateFromRemote(String branchName, [String remoteName = 'origin']);

  Future assertWorkingTreeClean();

  Future assertOnBranch(String branchName);

  Future checkout(String branchName);

  Future<bool> hasChangesSince(Version sinceVersion);

  Future tag(String tag, {String comment});

  /// fetches the contents of the given [filePath] as it was at the given
  /// [version].
  ///
  /// Throws [ArgumentError] if no git tag is found for the version
  Future<String> fetchFileContentsAt(Version version, String filePath);
}
