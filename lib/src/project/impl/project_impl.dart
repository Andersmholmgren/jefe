// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.impl;

import 'dart:async';
import '../project.dart';
import 'package:git/git.dart';
import '../../git/git.dart';
import 'package:logging/logging.dart';
import '../../spec/jefe_spec.dart';
import 'package:jefe/src/project/impl/project_group_impl.dart';
import 'dart:io';
import 'package:pubspec/pubspec.dart';
import 'core_impl.dart';
import 'package:analyzer/analyzer.dart';
import 'package:path/path.dart' as p;
import 'package:option/option.dart';

Logger _log = new Logger('jefe.project.impl');

class ProjectReferenceImpl implements ProjectReference {
  final ProjectGroupImpl parent;
  final ProjectIdentifier ref;
  ProjectReferenceImpl(this.parent, this.ref);

  @override
  Future<Project> get() => parent.getChildProject(name, gitUri);

  @override
  String get gitUri => ref.gitUri;

  @override
  String get name => ref.name;
}

class ProjectImpl extends ProjectEntityImpl implements Project {
  PubSpec _pubspec;

  PubSpec get pubspec => _pubspec;

  String get name => pubspec.name;

  ProjectIdentifier get id => new ProjectIdentifier(name, gitUri);

  ProjectImpl(String gitUri, Directory installDirectory, this._pubspec)
      : super(gitUri, installDirectory);

  static Future<ProjectImpl> install(
      Directory parentDir, String name, String gitUri,
      {bool updateIfExists}) async {
    _log.info('installing project $name from $gitUri into $parentDir');

    final projectParentDir = await parentDir.create(recursive: true);

    final GitDir gitDir = await cloneOrPull(
        gitUri,
        projectParentDir,
        new Directory(gitWorkspacePath(gitUri, projectParentDir)),
        OnExistsAction.ignore);

    final installDirectory = new Directory(gitDir.path);
    return new ProjectImpl(
        gitUri, installDirectory, await PubSpec.load(installDirectory));
  }

  static Future<Project> load(Directory installDirectory) async {
    _log.info('loading project from install directory $installDirectory');
    final GitDir gitDir = await GitDir.fromExisting(installDirectory.path);

    final PubSpec pubspec = await PubSpec.load(installDirectory);

    final String gitUri = await getOriginOrFirstRemote(gitDir);
    return new ProjectImpl(gitUri, installDirectory, pubspec);
  }

  @override
  Future updatePubspec(PubSpec newSpec) async {
    _log.info('Updating pubspec for project ${name}');
    await newSpec.save(installDirectory);
    _pubspec = newSpec;
    _log.finest('Finished Updating pubspec for project ${name}');
  }

  @override
  Future<String> get currentGitCommitHash async =>
      currentCommitHash(await gitDir);

  @override
  Future<Option<CompilationUnit>> get compilationUnit async {
    final mainLibraryPath =
        p.join(installDirectory.path, 'lib', '${name}.dart');
    final exists = await new File(mainLibraryPath).exists();
    return exists ? new Some(parseDartFile(mainLibraryPath)) : const None();
  }

  String toString() => 'Project($name, $gitUri)';

  @override
  Future<Iterable<String>> get exportedDependencyNames async {
    final Iterable<Directive> exports = (await compilationUnit)
        .map((cu) => cu.directives.where((d) => d is ExportDirective))
        .getOrDefault(const []);

    final exportedPackageNames = await exports
        .map((exp) => exp.uri.stringValue)
        .where((uri) => uri.startsWith('package:'))
        .map((String uri) => uri.substring('package:'.length, uri.indexOf('/')))
        .toSet();

    return pubspec.dependencies.keys
        .where((n) => exportedPackageNames.contains(n));
  }
}
