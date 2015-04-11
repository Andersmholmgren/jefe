library devops.project.metadata.yaml;

import 'project.dart';
import 'project_impl.dart';

import 'package:yaml/yaml.dart';
import 'dart:io';
import 'dart:async';

Future<ProjectGroupMetaData> readProjectGroupYaml(File projectgroupFile) async {
  final Map yaml = loadYaml(await projectgroupFile.readAsString());

  print(yaml);

  final Map projectgroupsMap = yaml['projectgroups'] != null ? yaml['projectgroups'] : {};
  print(projectgroupsMap);

  final Map modulesMap = yaml['modules'] != null ? yaml['modules'] : {};
  print(modulesMap);

  final childProjectGroups = projectgroupsMap.keys
      .map((k) => new ProjectGroupRefImpl(k, Uri.parse(projectgroupsMap[k])));

  final childModules = modulesMap.keys
      .map((k) => new ModuleRefImpl(k, Uri.parse(modulesMap[k])));

  return new ProjectGroupMetaDataImpl(yaml['name'], childProjectGroups, childModules);
}
