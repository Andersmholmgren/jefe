// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.operations.all;

import 'package:jefe/src/project_operations/docker_commands.dart';
import 'package:jefe/src/project_operations/git_commands.dart';
import 'package:jefe/src/project_operations/git_feature.dart';
import 'package:jefe/src/project_operations/process_commands.dart';
import 'package:jefe/src/project_operations/pub_commands.dart';
import 'package:jefe/src/project_operations/pubspec_commands.dart';
import 'package:jefe/src/project_operations/project_lifecycle.dart';

final DockerCommands docker = new DockerCommands();
final GitCommands git = new GitCommands();
final GitFeatureCommands feature = new GitFeatureCommands();
final ProcessCommands process = new ProcessCommands();
final PubCommands pub = new PubCommands();
final PubSpecCommands pubSpec = new PubSpecCommands();
final ProjectLifecycle lifecycle = new ProjectLifecycle();
