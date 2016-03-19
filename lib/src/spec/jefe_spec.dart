// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.spec;

import 'dart:async';
import 'dart:io';

import 'package:jefe/jefe.dart';
import 'package:jefe/src/spec/impl/jefe_yaml.dart';
import 'package:path/path.dart' as p;

import 'impl/jefe_spec_impl.dart';
import 'package:stuff/stuff.dart';

/// The meta data that defines a [ProjectGroup]. This is read from the group's
/// jefe.yaml file
abstract class ProjectGroupMetaData implements Jsonable {
  String get name;

  Iterable<ProjectGroupIdentifier> get childGroups;

  Iterable<ProjectIdentifier> get projects;

  factory ProjectGroupMetaData(
      String name,
      Iterable<ProjectGroupIdentifier> childGroups,
      Iterable<ProjectIdentifier> projects) = ProjectGroupMetaDataImpl;

  static Future<ProjectGroupMetaData> fromDefaultProjectGroupYamlFile(
          String projectGroupDirectory) =>
      fromProjectGroupYamlFile(p.join(projectGroupDirectory, 'jefe.yaml'));

  static Future<ProjectGroupMetaData> fromProjectGroupYamlFile(
          String projectGroupFile) =>
      readProjectGroupYaml(new File(projectGroupFile));
}

abstract class ProjectEntityIdentifier<T> implements Jsonable {
  String get name;
  String get gitUri;
}

abstract class ProjectGroupIdentifier
    implements ProjectEntityIdentifier<ProjectGroup> {
  factory ProjectGroupIdentifier(
      String name, String gitUri) = ProjectGroupIdentifierImpl;
}

abstract class ProjectIdentifier implements ProjectEntityIdentifier<Project> {
  factory ProjectIdentifier(String name, String gitUri) = ProjectIdentifierImpl;
}
