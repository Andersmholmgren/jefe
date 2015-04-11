library devops.project.impl;

import 'dart:async';
import 'project.dart';
import 'dart:io';
import 'package:git/git.dart';
import 'package:devops/src/git.dart';
import 'package:path/path.dart' as p;
import 'package:quiver/iterables.dart';
import 'package:logging/logging.dart';

Logger _log = new Logger('devops.project.impl');

abstract class _BaseRef<T> implements Ref<T> {
  final String name;
  final Uri gitUri;

  _BaseRef(this.name, this.gitUri);
}

class ProjectRefImpl extends _BaseRef implements ProjectRef {
  ProjectRefImpl(String name, Uri gitUri) : super(name, gitUri);

  @override
  Future<Project> install(Directory parentDir, {bool recursive: true}) async {
    _log.info('installing project $name from $gitUri into $parentDir');

    final Directory projectRoot =
        await new Directory(gitWorkspacePath(gitUri, parentDir) + '_root')
            .create(recursive: true);

    final GitDir gitDir = await clone(gitUri, projectRoot);

    final ProjectMetaData metaData = await ProjectMetaData
        .fromProjectYaml(p.join(gitDir.path, 'project.yaml'));

    final projectDir = new Directory(gitDir.path);
    final project = new ProjectImpl(gitUri, metaData, projectDir);
    if (recursive) {
      final projectInstallFutures = metaData.childProjects
          .map((ref) => ref.install(projectRoot, recursive: true));
      final moduleInstallFutures = metaData.modules
          .map((ref) => ref.install(projectRoot, recursive: true));
      await Future.wait(concat([projectInstallFutures, moduleInstallFutures]));
    }
    return project;
  }
}

class ModuleRefImpl extends _BaseRef implements ModuleRef {
  ModuleRefImpl(String name, Uri gitUri) : super(name, gitUri);

  @override
  Future<Module> install(Directory parentDir, {bool recursive: true}) async {
    _log.info('installing module $name from $gitUri into $parentDir');
    
    final GitDir gitDir = await clone(gitUri, parentDir);
    return new ModuleImpl(gitUri, new Directory(gitUri.path));
  }
}

class ProjectImpl implements Project {
  final Uri gitUri;
  final ProjectMetaData metaData;
  final Directory installDirectory;

  ProjectImpl(this.gitUri, this.metaData, this.installDirectory);

  @override
  Future release({bool recursive: true, ReleaseType type: ReleaseType.minor}) {
    // TODO: implement release
  }

  @override
  Future setupForDev({bool recursive: true}) {
    // TODO: implement setupForDev
  }

  @override
  Future update({bool recursive: true}) {
    // TODO: implement update
  }

  @override
  Future<Project> childProject(ProjectRef ref) {
    // TODO: implement childProject
  }

  @override
  Future featureEnd(String name, {bool recursive: true}) {
    // TODO: implement featureEnd
  }

  @override
  Future featureStart(String name, {bool recursive: true}) {
    // TODO: implement featureStart
  }

  @override
  Future initFlow({bool recursive: true}) {
    // TODO: implement initFlow
  }
}

class ModuleImpl implements Module {
  final Uri gitUri;

  final Directory installDirectory;

  ModuleImpl(this.gitUri, this.installDirectory);
}

class ProjectMetaDataImpl implements ProjectMetaData {
  final String name;
  final Iterable<ProjectRef> childProjects;
  final Iterable<ModuleRef> modules;

  ProjectMetaDataImpl(this.name, this.childProjects, this.modules);
}
