library devops.project.impl;

import 'dart:async';
import 'project.dart';
import 'dart:io';
import 'package:git/git.dart';
import 'package:devops/src/git.dart';
import 'package:quiver/iterables.dart';
import 'package:logging/logging.dart';
import 'package:den_api/den_api.dart';
import 'package:path/path.dart' as p;

Logger _log = new Logger('devops.project.impl');

abstract class _BaseRef<T> implements Ref<T> {
  final String name;
  final Uri gitUri;

  _BaseRef(this.name, this.gitUri);

  Directory installDirectory(Directory parent) =>
      new Directory(p.join(parent.path, name));
}

class ProjectGroupRefImpl extends _BaseRef implements ProjectGroupRef {
  ProjectGroupRefImpl(String name, Uri gitUri) : super(name, gitUri);

  @override
  Future<ProjectGroup> install(Directory parentDir,
      {bool recursive: true}) async {
    _log.info('installing group $name from $gitUri into $parentDir');

    final Directory projectGroupRoot =
        await new Directory(gitWorkspacePath(gitUri, parentDir) + '_root')
            .create(recursive: true);

    final GitDir gitDir = await clone(gitUri, projectGroupRoot);

    final ProjectGroupMetaData metaData =
        await ProjectGroupMetaData.fromDefaultProjectGroupYamlFile(gitDir.path);

    final projectGroupDir = new Directory(gitDir.path);
    final projectGroup =
        new ProjectGroupImpl(gitUri, metaData, projectGroupDir);
    if (recursive) {
      final projectGroupInstallFutures = metaData.childGroups
          .map((ref) => ref.install(projectGroupRoot, recursive: true));
      final projectInstallFutures = metaData.projects
          .map((ref) => ref.install(projectGroupRoot, recursive: true));
      await Future
          .wait(concat([projectGroupInstallFutures, projectInstallFutures]));
    }
    return projectGroup;
  }

  @override
  Future<ProjectGroup> load(Directory parentDirectory,
          {bool recursive: true}) =>
      ProjectGroup.fromInstallDirectory(installDirectory(parentDirectory));
}

class ProjectRefImpl extends _BaseRef implements ProjectRef {
  ProjectRefImpl(String name, Uri gitUri) : super(name, gitUri);

  @override
  Future<Project> install(Directory parentDir, {bool recursive: true}) async {
    _log.info('installing project $name from $gitUri into $parentDir');

    final GitDir gitDir = await clone(gitUri, parentDir);
    return new ProjectImpl(gitUri, new Directory(gitUri.path));
  }

  @override
  Future<Project> load(Directory parentDirectory, {bool recursive: true}) =>
      Project.fromInstallDirectory(installDirectory(parentDirectory));
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

  @override
  Future<Set<Project>> get allProjects {
//    metaData.projects
  }

  static Future _addAll(Set<Project> projects, ProjectGroup group) {
    projects.addAll(group.metaData.projects);
  }

  @override
  Future processDependenciesDepthFirst(
      process(Project project, Iterable<Project> dependencies)) {
    // TODO: implement processDependenciesDepthFirst
  }
}

class ProjectImpl implements Project {
  final Uri gitUri;

  final Directory installDirectory;

  Future<Pubspec> get pubspec => Pubspec.load(installDirectory.path);

  ProjectImpl(this.gitUri, this.installDirectory);
}

class ProjectGroupMetaDataImpl implements ProjectGroupMetaData {
  final String name;
  final Iterable<ProjectGroupRef> childGroups;
  final Iterable<ProjectRef> projects;

  ProjectGroupMetaDataImpl(this.name, this.childGroups, this.projects);
}

Future<ProjectGroup> loadProjectGroupFromInstallDirectory(
    Directory installDirectory) async {
  final gitDirFuture = GitDir.fromExisting(installDirectory.path);
  final metaDataFuture = ProjectGroupMetaData
      .fromDefaultProjectGroupYamlFile(installDirectory.path);
  final results = await Future.wait([gitDirFuture, metaDataFuture]);

  final GitDir gitDir = results.first;

  final Uri gitUri = await getFirstRemote(gitDir);
  return new ProjectGroupImpl(gitUri, results.elementAt(1), installDirectory);
}

Future<Project> loadProjectFromInstallDirectory(
    Directory installDirectory) async {
  final GitDir gitDir = await GitDir.fromExisting(installDirectory.path);

  final Uri gitUri = await getFirstRemote(gitDir);
  return new ProjectImpl(gitUri, installDirectory);
}
