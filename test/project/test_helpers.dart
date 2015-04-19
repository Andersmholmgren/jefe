library devops.project.test.helpers;

import 'package:devops/src/project/project.dart';
import 'package:devops/src/pubspec/dependency.dart';
import 'dart:io';
import 'package:devops/src/project/impl/project_impl.dart';
import 'package:devops/src/pubspec/pubspec.dart';

Project aProject(String name, {Iterable<Project> dependencies: const []}) =>
    __aProject(name,
        pathDependencies: dependencies.map((p) => new PathReference(p.name)));

Project __aProject(String name,
    {Iterable<PathReference> pathDependencies: const []}) {
  final dependencies = {};
  pathDependencies.forEach((pd) {
    // WARNING: only makes sense if path == name
    dependencies[pd.path] = pd;
  });

  return new ProjectImpl(name, new Directory(name),
      new PubSpec(name: name, dependencies: dependencies));
}
