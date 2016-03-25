// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.spec.impl;

import 'dart:async';
import 'dart:io';

import 'package:jefe/src/project/project.dart';
import 'package:jefe/src/project/project_group.dart';
import 'package:path/path.dart' as p;
import 'package:stuff/stuff.dart';
import 'package:yamlicious/yamlicious.dart';

import '../jefe_spec.dart';

class ProjectGroupMetaDataImpl implements ProjectGroupMetaData {
  final String name;
  final Iterable<ProjectGroupIdentifier> childGroups;
  final Iterable<ProjectIdentifier> projects;

  ProjectGroupMetaDataImpl(this.name, this.childGroups, this.projects);

  @override
  Future save(Directory projectDirectory) {
    final ioSink =
        new File(p.join(projectDirectory.path, 'jefe.yaml')).openWrite();
    try {
      writeYamlString(toJson(), ioSink);
    } finally {
      return ioSink.close();
    }
  }

  @override
  Map toJson() => (buildJson
        ..add('name', name)
        ..add(
            'childGroups',
            new Map.fromIterable(childGroups,
                key: (ProjectGroupIdentifier g) => g.name,
                value: (ProjectGroupIdentifier g) => g.gitUri))
        ..add(
            'projects',
            new Map.fromIterable(projects,
                key: (ProjectIdentifier g) => g.name,
                value: (ProjectIdentifier g) => g.gitUri)))
      .json;
}

abstract class _BaseRef<T> implements ProjectEntityIdentifier<T>, Jsonable {
  final String name;
  final String gitUri;

  _BaseRef(this.name, this.gitUri);

  bool operator ==(other) =>
      other.runtimeType == runtimeType &&
      name == other.name &&
      gitUri == other.gitUri;

  int get hashCode => name.hashCode;

  Map toJson() => {name: gitUri};
}

class ProjectGroupIdentifierImpl extends _BaseRef<ProjectGroup>
    implements ProjectGroupIdentifier {
  ProjectGroupIdentifierImpl(String name, String gitUri) : super(name, gitUri);

  String toString() => 'ProjectGroupRef($name, $gitUri)';
}

class ProjectIdentifierImpl extends _BaseRef<Project>
    implements ProjectIdentifier {
  ProjectIdentifierImpl(String name, String gitUri) : super(name, gitUri);

  String toString() => 'ProjectRef($name, $gitUri)';
}
