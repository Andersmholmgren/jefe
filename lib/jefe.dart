// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// The jefe library.
///
/// A library for maintaining sets of related Dart projects versioned in git,
/// in particular managing dependencies between them.
///
/// At the centre of Jefe is a model of a group of projects [ProjectGroup].
/// A [ProjectGroup] has a [installDirectory] where it is installed locally and
/// a [gitUri] where it's metaData (jefe.yaml) lives.
///
/// A [ProjectGroup] contains a set of [Project]s which is a representation of
/// a Dart project that is being managed by Jefe.
///
/// Additionally, it may have child [ProjectGroup]s so forms a tree structure.
///
/// It provides access to the [dependencyGraph] which a representation of all
/// the Project's in the tree structure and the dependencies between them.
///
/// Typically, you interact with the [ProjectGraph] by using a [CommandExecutor]
/// to execute commands against the tree.
///
/// For example
///
///     final executor = await executorForDirectory('/Users/blah/myfoo_root');
///     await executor.execute(docker.generateProductionDockerfile(
///       'my_server', 'my_client',
///       dartVersion: '1.9.3',
///       environment: {'MY_FOO': false},
///       exposePorts: [8080, 8181, 5858],
///       entryPointOptions: ["--debug:5858/0.0.0.0"]));
///
/// executes a command to generate a Dockerfile for the ProjectGroup installed
/// at /Users/blah/myfoo_root
///
/// Most commands tend to operate on a single project. For example
///
///     await executor.execute(lifecycle.completeFeature('feacha'));
///
///
library jefe;

export 'src/project/dependency_graph.dart';
export 'src/project/project.dart';
export 'src/project/project_group.dart';
export 'src/project/release_type.dart';
export 'src/project/docker_commands.dart';
export 'src/project/git_commands.dart';
export 'src/project/git_feature.dart';
export 'package:jefe/src/project/process_commands.dart';
export 'src/project_commands/project_command.dart';
export 'src/project_commands/project_command_executor.dart';
export 'src/project/project_lifecycle.dart';
export 'src/project/pub_commands.dart';
export 'src/project/pubspec_commands.dart';
export 'src/project/jefe_project.dart';
export 'src/spec/jefe_spec.dart';
