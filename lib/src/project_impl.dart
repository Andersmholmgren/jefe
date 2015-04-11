library devops.project.impl;

import 'dart:async';
import 'project.dart';
import 'dart:io';
import 'package:git/git.dart';
import 'package:devops/src/git.dart';
import 'package:path/path.dart' as p;

class ProjectRefImpl implements ProjectRef {
  final String name;
  final Uri gitUri;

  ProjectRefImpl(this.name, this.gitUri);

  // TODO: implement fetch

  @override
  Future<Project> install(Directory parentDir, {bool recursive: true}) async {
    final Directory projectRoot =
        new Directory(gitWorkspacePath(gitUri, parentDir) + '_root');

    await projectRoot.create(recursive: true);

    final GitDir gitDir = await clone(gitUri, projectRoot);

    final ProjectMetaData metaData = await ProjectMetaData
        .fromProjectYaml(p.join(gitDir.path, 'project.yaml'));

    final projectDir = new Directory(gitDir.path);
    final project = new ProjectImpl(gitUri, metaData, projectDir);
    if (recursive) {
      await Future.wait(metaData.childProjects
          .map((ref) => ref.install(projectRoot, recursive: true)));
    }
    return project;
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
}

class ModuleImpl implements Module {}

class ProjectMetaDataImpl implements ProjectMetaData {
  final String name;
  final Iterable<ProjectRef> childProjects;
  final Iterable<ModuleRef> modules;

  ProjectMetaDataImpl(this.name, this.childProjects, this.modules);
}
