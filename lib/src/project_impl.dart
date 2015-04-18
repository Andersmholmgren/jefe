library devops.project.impl;

import 'dart:async';
import 'project.dart';
import 'package:git/git.dart';
import 'package:devops/src/git/git.dart';
import 'package:logging/logging.dart';
import 'package:devops/src/pubspec/pubspec.dart';
import 'package:devops/src/pubspec/dependency.dart';
import 'pub.dart' as pub;
import 'package:devops/src/spec/JefeSpec.dart';
import 'package:devops/src/project_group_impl.dart';
import 'dart:io';

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
      Directory parentDir, String name, String gitUri,
      {bool recursive: true}) async {
    _log.info('installing project $name from $gitUri into $parentDir');

    await parentDir.create(recursive: true);

    final GitDir gitDir = await clone(gitUri, parentDir);
    final installDirectory = new Directory(gitDir.path);
    return new ProjectImpl(
        gitUri, installDirectory, await PubSpec.load(installDirectory));
  }

  static Future<Project> load(Directory installDirectory) async {
    _log.info('loading project from install directory $installDirectory');
//    print(
//        '--- ProjectImpl.load: loading git dir from ${installDirectory.path}');
    final GitDir gitDir = await GitDir.fromExisting(installDirectory.path);

    final PubSpec pubspec = await PubSpec.load(installDirectory);

    final String gitUri = await getFirstRemote(gitDir);
    return new ProjectImpl(gitUri, installDirectory, pubspec);
  }

  @override
  Future release(Iterable<Project> dependencies,
      {ReleaseType type: ReleaseType.minor}) async {
    final newVersion = type.bump(pubspec.version);
    await releaseStart(newVersion.toString());
    await updatePubspec(pubspec.copy(version: newVersion));
    await setToGitDependencies(dependencies);
    await commit('releasing version $newVersion');
    await releaseFinish(newVersion.toString());
    await push();
  }

  @override
  Future updatePubspec(PubSpec newSpec) async {
    _log.info('Updating pubspec for project ${name}');
    await newSpec.save(installDirectory);
    _pubspec = newSpec;
    _log.finest('Finished Updating pubspec for project ${name}');
  }

  @override
  Future initFlow() async {
    _log.info('Initializing git flow for project ${name}');
    await initGitFlow(await gitDir);
    _log.finer('Initialized git flow for project ${name}');
  }

  @override
  Future featureStart(String featureName) async {
    _log.info('Starting feature $featureName for project ${name}');
    await gitFlowFeatureStart(await gitDir, featureName);
    _log.finer('Started feature $featureName for project ${name}');
  }

  @override
  Future featureFinish(String featureName) async {
    _log.info('git flow feature finish $featureName for project ${name}');
    await gitFlowFeatureFinish(await gitDir, featureName);
    _log.finer(
        'completed git flow feature finish $featureName for project ${name}');
  }

  @override
  Future releaseStart(String version) async {
    _log.info('git flow release start $version for project ${name}');
    await gitFlowReleaseStart(await gitDir, version);
    _log.finer('git flow release started $version for project ${name}');
  }

  @override
  Future releaseFinish(String version) async {
    _log.info('git flow release finish $version for project ${name}');
    var _gitDir = await gitDir;
    await gitFlowReleaseFinish(_gitDir, version);
    // bug in git flow prevents tagging with -m working so run with -n
    // and tag manually
    await gitTag(_gitDir, version);
    _log.finest(
        'completed git flow release finish $version for project ${name}');
  }

  @override
  Future setToPathDependencies(Iterable<Project> dependencies) async {
    await _setDependencies('path', dependencies, (Project p) =>
        new Future.value(new PathReference(p.installDirectory.path)));
  }

  @override
  Future setToGitDependencies(Iterable<Project> dependencies) async {
    await _setDependencies('git', dependencies, (Project p) async =>
        await new GitReference(gitUri, await currentGitCommitHash));
  }

  @override
  Future<String> get currentGitCommitHash async =>
      currentCommitHash(await gitDir);

  Future _setDependencies(String type, Iterable<Project> dependencies,
      Future<DependencyReference> createReferenceTo(Project p)) async {
    _log.info('Setting up $type dependencies for project ${name}');
    if (dependencies.isEmpty) {
      _log.finest('No depenencies for project ${name}');
      return;
    }

    final PubSpec _pubspec = await pubspec;
    final newDependencies = new Map.from(_pubspec.dependencies);

    await Future.wait(dependencies.map((p) async {
      final ref = await createReferenceTo(p);
      _log.finest('created reference $ref for project ${name}');
      newDependencies[p.name] = ref;
    }));

    final newPubspec = _pubspec.copy(dependencies: newDependencies);
    await updatePubspec(newPubspec);
    _log.finer('Finished setting up $type dependencies for project ${name}');
  }

  @override
  Future commit(String message) async {
    _log.info('Commiting project ${name} with message $message');
    return gitCommit(await gitDir, message);
  }

  @override
  Future push() async {
    _log.info('Pushing project ${name}');
//    return gitPush(await gitDir);
  }

  @override
  Future pubGet() async {
    _log.info('Running pub get for project ${name}');
    final stopWatch = new Stopwatch()..start();
    await pub.get(installDirectory);
    _log.finest(
        'Completed pub get for project ${name} in ${stopWatch.elapsed}');
    stopWatch.stop();
  }

  String toString() => 'Project($name, $gitUri)';
}
