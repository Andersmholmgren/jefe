// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.test.helpers;

import 'dart:io';

import 'package:jefe/src/project/impl/project_impl.dart';
import 'package:jefe/src/project/project.dart';
import 'package:pubspec/pubspec.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project/impl/jefe_project_impl.dart';

JefeProject aProject(String name, {Iterable<Project> dependencies: const []}) {
  final mappedDependencies =
      dependencies.map((p) => new JefeProjectImpl.from([], p));

  return new JefeProjectImpl.from(
      mappedDependencies,
      __aProject(name,
          pathDependencies:
              dependencies.map((p) => new PathReference(p.name))));
}

Project __aProject(String name,
    {Iterable<PathReference> pathDependencies: const []}) {
  final dependencies = <String, DependencyReference>{};
  pathDependencies.forEach((pd) {
    // WARNING: only makes sense if path == name
    dependencies[pd.path] = pd;
  });

  return new ProjectImpl(name, new Directory(name),
      new PubSpec(name: name, dependencies: dependencies), null);
}

//JefeProjectSet
