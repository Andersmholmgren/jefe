// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.intellij.impl;

import 'dart:async';

import 'package:jefe/src/project/impl/multi_project_command_support.dart';
import 'package:jefe/src/project/intellij_commands.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project_commands/project_command.dart';
import 'package:logging/logging.dart';
//import 'package:stuff/stuff.dart';
import 'package:quiver/iterables.dart';

Logger _log = new Logger('jefe.project.commands.intellij.impl');

IntellijCommands createIntellijCommands(JefeProjectGraph graph,
    {bool multiProject: true,
    CommandConcurrencyMode defaultConcurrencyMode,
    ProjectFilter projectFilter}) {
  return multiProject
      ? new IntellijCommandsMultiProjectImpl(graph,
          defaultConcurrencyMode: defaultConcurrencyMode,
          projectFilter: projectFilter)
      : new IntellijCommandsSingleProjectImpl(graph as JefeProject);
}

class IntellijCommandsSingleProjectImpl
    extends SingleProjectCommandSupport<IntellijCommands>
    implements IntellijCommands {
  IntellijCommandsSingleProjectImpl(JefeProject project)
      : super(
            (JefeProject p) async =>
                new _IntellijCommandsSingleProjectImpl(project),
            project);
}

class IntellijCommandsMultiProjectImpl
    extends MultiProjectCommandSupport<IntellijCommands>
    implements IntellijCommands {
  IntellijCommandsMultiProjectImpl(JefeProjectGraph graph,
      {CommandConcurrencyMode defaultConcurrencyMode,
      ProjectFilter projectFilter})
      : super(graph,
            (JefeProject p) async => new IntellijCommandsSingleProjectImpl(p),
            defaultConcurrencyMode: defaultConcurrencyMode,
            projectFilter: projectFilter);

  @override
  Future<IntellijVcsMappings> generateGitMappings(
      String intelliJProjectRootPath) async {
    IntellijVcsMappings combine(
        IntellijVcsMappings previous, IntellijVcsMappings current) {
      return new IntellijVcsMappings(
          concat([previous.vcsDirectoryMappings, current.vcsDirectoryMappings]));
    }
    return process<IntellijVcsMappings>(
        'generateGitMappings',
        (JefeProject p) async => (await singleProjectCommandFactory(p))
            .generateGitMappings(intelliJProjectRootPath),
        combine: combine);
  }
}

class _IntellijCommandsSingleProjectImpl implements IntellijCommands {
  final JefeProject _project;

  _IntellijCommandsSingleProjectImpl(this._project);

  @override
  Future<IntellijVcsMappings> generateGitMappings(
      String intelliJProjectRootPath) async {
    return new IntellijVcsMappings(<IntellijVcsMapping>[
      new IntellijVcsMapping(
          _project.installDirectory.path, intelliJProjectRootPath)
    ]);
  }
}
