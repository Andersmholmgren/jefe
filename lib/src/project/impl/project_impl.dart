library devops.project.impl;

import 'dart:async';
import '../project.dart';
import 'package:git/git.dart';
import '../../git/git.dart';
import 'package:logging/logging.dart';
import '../../spec/JefeSpec.dart';
import 'package:devops/src/project/impl/project_group_impl.dart';
import 'dart:io';
import 'package:devops/src/project/core.dart';
import 'package:pubspec/pubspec.dart';

Logger _log = new Logger('devops.project.impl');

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

abstract class ProjectEntityImpl implements ProjectEntity {
  final String gitUri;
  final Directory installDirectory;

  ProjectEntityImpl(this.gitUri, this.installDirectory);

  @override
  Future<GitDir> get gitDir {
//    print('--- loading git dir from ${installDirectory.path}');
    return GitDir.fromExisting(installDirectory.path);
  }
}

class ProjectImpl extends ProjectEntityImpl implements Project {
  PubSpec _pubspec;

  PubSpec get pubspec => _pubspec;

  String get name => pubspec.name;

  ProjectIdentifier get id => new ProjectIdentifier(name, gitUri);

  ProjectImpl(String gitUri, Directory installDirectory, this._pubspec)
      : super(gitUri, installDirectory);

  static Future<ProjectImpl> install(
      Directory parentDir, String name, String gitUri) async {
    _log.info('installing project $name from $gitUri into $parentDir');

    await parentDir.create(recursive: true);

    final GitDir gitDir = await clone(gitUri, parentDir);
    final installDirectory = new Directory(gitDir.path);
    return new ProjectImpl(
        gitUri, installDirectory, await PubSpec.load(installDirectory));
  }

  static Future<Project> load(Directory installDirectory) async {
    _log.info('loading project from install directory $installDirectory');
    final GitDir gitDir = await GitDir.fromExisting(installDirectory.path);

    final PubSpec pubspec = await PubSpec.load(installDirectory);

    final String gitUri = await getFirstRemote(gitDir);
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

  String toString() => 'Project($name, $gitUri)';
}
