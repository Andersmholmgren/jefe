library devops.project;

import 'dart:async';
import 'dart:io';
import 'impl/project_impl.dart';
import 'package:git/git.dart';
import '../pubspec/pubspec.dart';
import '../spec/JefeSpec.dart';

abstract class ProjectEntityReference<T extends ProjectEntity>
    extends ProjectEntityIdentifier {
  Future<T> get();
}

abstract class ProjectReference implements ProjectEntityReference<Project> {}

abstract class ProjectEntity {
  String get name;
  String get gitUri;
  Future<GitDir> get gitDir;
  Directory get installDirectory;
}

abstract class Project extends ProjectEntity {
  PubSpec get pubspec;
  ProjectIdentifier get id;

  static Future<Project> install(
          Directory parentDir, String name, String gitUri,
          {bool recursive: true}) =>
      ProjectImpl.install(parentDir, name, gitUri, recursive: recursive);

  static Future<Project> load(Directory installDirectory) =>
      ProjectImpl.load(installDirectory);

  Future<String> get currentGitCommitHash;

  Future updatePubspec(PubSpec newSpec);
}
