library devops.project.metadata.yaml;

import 'package:yaml/yaml.dart';
import 'dart:io';
import 'dart:async';
import 'package:devops/src/spec/JefeSpec.dart';
import 'package:logging/logging.dart';

Logger _log = new Logger('devops.project.metadata.yaml');

Future<ProjectGroupMetaData> readProjectGroupYaml(File projectGroupFile) async {
  final Map yaml = loadYaml(await projectGroupFile.readAsString());

  _log.finer('reading project.yaml $projectGroupFile');
//  print(yaml);

  final Map projectGroupsMap = yaml['groups'] != null ? yaml['groups'] : {};
//  print(projectGroupsMap);

  final Map projectsMap = yaml['projects'] != null ? yaml['projects'] : {};
//  print(projectsMap);

  final childProjectGroups = projectGroupsMap.keys
      .map((k) => new ProjectGroupRefImpl(k, projectGroupsMap[k]));

  final childProjects =
      projectsMap.keys.map((k) => new ProjectIdentifierImpl(k, projectsMap[k]));

  return new ProjectGroupMetaDataImpl(
      yaml['name'], childProjectGroups, childProjects);
}
