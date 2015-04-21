// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.spec.impl;

import '../jefe_spec.dart';

class ProjectGroupMetaDataImpl implements ProjectGroupMetaData {
  final String name;
  final Iterable<ProjectGroupIdentifier> childGroups;
  final Iterable<ProjectIdentifier> projects;

  ProjectGroupMetaDataImpl(this.name, this.childGroups, this.projects);
}

abstract class _BaseRef<T> implements ProjectEntityIdentifier<T> {
  final String name;
  final String gitUri;

  _BaseRef(this.name, this.gitUri);

  bool operator ==(other) => other.runtimeType == runtimeType &&
      name == other.name &&
      gitUri == other.gitUri;

  int get hashCode => name.hashCode;
}

class ProjectGroupIdentifierImpl extends _BaseRef
    implements ProjectGroupIdentifier {
  ProjectGroupIdentifierImpl(String name, String gitUri) : super(name, gitUri);

  String toString() => 'ProjectGroupRef($name, $gitUri)';
}

class ProjectIdentifierImpl extends _BaseRef implements ProjectIdentifier {
  ProjectIdentifierImpl(String name, String gitUri) : super(name, gitUri);

  String toString() => 'ProjectRef($name, $gitUri)';
}
