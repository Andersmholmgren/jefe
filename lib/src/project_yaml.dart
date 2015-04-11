library devops.project.metadata.yaml;

import 'project.dart';
import 'project_impl.dart';

import 'package:yaml/yaml.dart';
import 'dart:io';
import 'dart:async';

Future<ProjectMetaData> readProjectYaml(File projectFile) async {
  final Map yaml = loadYaml(await projectFile.readAsString());

  print(yaml);

  final Map projectsMap = yaml['projects'] != null ? yaml['projects'] : {};
  print(projectsMap);

  final Map modulesMap = yaml['modules'] != null ? yaml['modules'] : {};
  print(modulesMap);

  final childProjects = projectsMap.keys
      .map((k) => new ProjectRefImpl(k, Uri.parse(projectsMap[k])));

  final childModules = modulesMap.keys
      .map((k) => new ModuleRefImpl(k, Uri.parse(modulesMap[k])));

  return new ProjectMetaDataImpl(yaml['name'], childProjects, childModules);
}
