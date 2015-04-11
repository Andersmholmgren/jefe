library devops.project.impl;

import 'dart:async';
import 'project.dart';
import 'dart:io';
import 'package:git/git.dart';
import 'package:devops/src/git.dart';
import 'project_yaml.dart';
import 'package:path/path.dart' as p;
import 'package:quiver/iterables.dart';
import 'package:logging/logging.dart';

Logger _log = new Logger('devops.project.impl');

abstract class _BaseRef<T> implements Ref<T> {
  final String name;
  final Uri gitUri;

  _BaseRef(this.name, this.gitUri);
}

class ProjectGroupRefImpl extends _BaseRef implements ProjectGroupRef {
  ProjectGroupRefImpl(String name, Uri gitUri) : super(name, gitUri);

  @override
  Future<ProjectGroup> install(Directory parentDir, {bool recursive: true}) async {
    _log.info('installing projectgroup $name from $gitUri into $parentDir');

    final Directory projectgroupRoot =
        await new Directory(gitWorkspacePath(gitUri, parentDir) + '_root')
            .create(recursive: true);

    final GitDir gitDir = await clone(gitUri, projectgroupRoot);

    final ProjectGroupMetaData metaData = await ProjectGroupMetaData
        .fromDefaultProjectGroupYamlFile(gitDir.path);

    final projectgroupDir = new Directory(gitDir.path);
    final projectgroup = new ProjectGroupImpl(gitUri, metaData, projectgroupDir);
    if (recursive) {
      final projectgroupInstallFutures = metaData.childProjectGroups
          .map((ref) => ref.install(projectgroupRoot, recursive: true));
      final projectInstallFutures = metaData.projects
          .map((ref) => ref.install(projectgroupRoot, recursive: true));
      await Future.wait(concat([projectgroupInstallFutures, projectInstallFutures]));
    }
    return projectgroup;
  }
}

class ProjectRefImpl extends _BaseRef implements ProjectRef {
  ProjectRefImpl(String name, Uri gitUri) : super(name, gitUri);

  @override
  Future<Project> install(Directory parentDir, {bool recursive: true}) async {
    _log.info('installing project $name from $gitUri into $parentDir');

    final GitDir gitDir = await clone(gitUri, parentDir);
    return new ProjectImpl(gitUri, new Directory(gitUri.path));
  }
}

class ProjectGroupImpl implements ProjectGroup {
  final Uri gitUri;
  final ProjectGroupMetaData metaData;
  final Directory installDirectory;

  ProjectGroupImpl(this.gitUri, this.metaData, this.installDirectory);

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
  Future<ProjectGroup> childProjectGroup(ProjectGroupRef ref) {
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

class ProjectImpl implements Project {
  final Uri gitUri;

  final Directory installDirectory;

  ProjectImpl(this.gitUri, this.installDirectory);
}

class ProjectGroupMetaDataImpl implements ProjectGroupMetaData {
  final String name;
  final Iterable<ProjectGroupRef> childProjectGroups;
  final Iterable<ProjectRef> projects;

  ProjectGroupMetaDataImpl(this.name, this.childProjectGroups, this.projects);
}



Future<ProjectGroup> loadProjectGroupFromInstallDirectory(Directory installDirectory) async {
  final gitDirFuture = GitDir.fromExisting(installDirectory.path);
  final metaDataFuture = ProjectGroupMetaData.fromDefaultProjectGroupYamlFile(installDirectory.path);
  final results = await Future.wait([gitDirFuture, metaDataFuture]);

  final GitDir gitDir = results.first;

  final Uri gitUri = await getFirstRemote(gitDir);
  return new ProjectGroupImpl(gitUri, results.elementAt(1), installDirectory);
}
