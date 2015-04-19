library devops.project;

import 'dart:async';
import 'dart:io';
import 'impl/project_impl.dart';
import '../pubspec/pubspec.dart';
import '../spec/JefeSpec.dart';
import 'core.dart';

abstract class ProjectReference implements ProjectEntityReference<Project> {}

/// Represents a Dart Project versioned with Git. Provides access to the
/// [PubSpec] and the git repository
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
