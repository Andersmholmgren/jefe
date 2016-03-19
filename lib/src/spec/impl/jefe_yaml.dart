// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.metadata.yaml;

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';
import 'package:yamlicious/yamlicious.dart';

import '../jefe_spec.dart';

Logger _log = new Logger('jefe.project.metadata.yaml');

/// Reads the [ProjectGroupMetaData] from the [File]
Future<ProjectGroupMetaData> readProjectGroupYaml(File projectGroupFile) async {
  final Map yaml = loadYaml(await projectGroupFile.readAsString());

  _log.finer('reading jefe.yaml $projectGroupFile');

  final Map projectGroupsMap = yaml['groups'] != null ? yaml['groups'] : {};

  final Map projectsMap = yaml['projects'] != null ? yaml['projects'] : {};

  final childProjectGroups = projectGroupsMap.keys
      .map((k) => new ProjectGroupIdentifier(k, projectGroupsMap[k]));

  final childProjects =
      projectsMap.keys.map((k) => new ProjectIdentifier(k, projectsMap[k]));

  return new ProjectGroupMetaData(
      yaml['name'], childProjectGroups, childProjects);
}

