library devops.project.metadata.yaml;

import 'project.dart';
import 'project_impl.dart';

import 'package:yaml/yaml.dart';
import 'dart:io';
import 'dart:async';

Future<ProjectGroupMetaData> readProjectGroupYaml(File projectgroupFile) async {
  final Map yaml = loadYaml(await projectgroupFile.readAsString());

  print(yaml);

  final Map projectgroupsMap = yaml['groups'] != null ? yaml['groups'] : {};
  print(projectgroupsMap);

  final Map projectsMap = yaml['projects'] != null ? yaml['projects'] : {};
  print(projectsMap);

  final childProjectGroups = projectgroupsMap.keys
      .map((k) => new ProjectGroupRefImpl(k, Uri.parse(projectgroupsMap[k])));

  final childProjects = projectsMap.keys
      .map((k) => new ProjectRefImpl(k, Uri.parse(projectsMap[k])));

  return new ProjectGroupMetaDataImpl(yaml['name'], childProjectGroups, childProjects);
}
