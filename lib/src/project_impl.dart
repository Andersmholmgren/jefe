library devops.project.impl;

import 'dart:async';
import 'project.dart';
import 'dart:io';
import 'package:git/git.dart';
import 'package:devops/src/git.dart';
import 'package:quiver/iterables.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'dependency_graph.dart';
import 'package:devops/src/pubspec/pubspec_model.dart';
import 'package:devops/src/pubspec/dependency.dart';

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
        await _containerDirectory(parentDir).create(recursive: true);

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

  Directory installDirectory(Directory parent) =>
      super.installDirectory(_containerDirectory(parent));

  Directory _containerDirectory(Directory parentDir) =>
      new Directory(gitWorkspacePath(gitUri, parentDir) + '_root');

//  Directory _installDirectory(Directory parentDir) =>
//      new Directory(p.join(_containerDirectory(parentDir).path, name));

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
    final installDirectory = new Directory(gitDir.path);
    return new ProjectImpl(
        gitUri, installDirectory, await PubSpec.load(installDirectory));
  }

  @override
  Future<Project> load(Directory parentDirectory, {bool recursive: true}) =>
      Project.fromInstallDirectory(installDirectory(parentDirectory));
}

abstract class ProjectEntityImpl implements ProjectEntity {
  final Uri gitUri;
  final Directory installDirectory;

  ProjectEntityImpl(this.gitUri, this.installDirectory);

  @override
  Future<GitDir> get gitDir {
    print('--- $installDirectory');
    return GitDir.fromExisting(installDirectory.path);
  }
}

class ProjectGroupImpl extends ProjectEntityImpl implements ProjectGroup {
  final ProjectGroupMetaData metaData;
  String get name => metaData.name;

  ProjectGroupImpl(Uri gitUri, this.metaData, Directory installDirectory)
      : super(gitUri, installDirectory);

  @override
  Future release({bool recursive: true, ReleaseType type: ReleaseType.minor}) {
    // TODO: implement release
  }

  @override
  Future setupForNewFeature(String featureName,
      {bool doPush: false, bool recursive: true}) async {
    await featureStart(featureName, recursive: recursive);
    await setToPathDependencies(recursive: recursive);
    await commit('set path dependencies for start of feature $featureName');
    if (doPush) {
      await push();
    }
    await pubGet();
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
  Future commit(String message) {
    // TODO: don't really need the graph traversal here
    _log.info(
        'Commiting all projects for group ${metaData.name} with message $message');
    return processDependenciesDepthFirst((Project project,
        Iterable<Project> dependencies) => project.commit(message));
  }

  @override
  Future push() {
    // TODO: don't really need the graph traversal here
    _log.info('Pushing all projects for group ${metaData.name}');
    return processDependenciesDepthFirst(
        (Project project, Iterable<Project> dependencies) => project.push());
  }

  @override
  Future setToPathDependencies({bool recursive: true}) {
    _log.info('Setting up path dependencies for group ${metaData.name}');
    return processDependenciesDepthFirst(
        (Project project, Iterable<Project> dependencies) =>
            project.setToPathDependencies(dependencies));
  }

  @override
  Future setToGitDependencies({bool recursive: true}) {
    _log.info('Setting up git dependencies for group ${metaData.name}');
    return processDependenciesDepthFirst(
        (Project project, Iterable<Project> dependencies) =>
            project.setToGitDependencies(dependencies));
  }

  @override
  Future initFlow({bool recursive: true}) async {
    _log.info('Initialising git flow for group ${metaData.name}');
    await Future.wait((await allProjects).map((p) => p.initFlow()));
  }

  @override
  Future featureStart(String name, {bool recursive: true}) async {
    _log.info('git flow feature start $name for group ${metaData.name}');
    await Future.wait((await allProjects).map((p) => p.featureStart(name)));
  }

  @override
  Future featureFinish(String name, {bool recursive: true}) async {
    _log.info('git flow feature finish $name for group ${metaData.name}');
    await Future.wait((await allProjects).map((p) => p.featureFinish(name)));
  }

  @override
  Future pubGet() async {
    _log.info('Running pub get for group ${name}');
    final stopWatch = new Stopwatch()..start();

    await Future.wait((await allProjects).map((p) => p.pubGet()));
    _log.finest('Completed pub get for group ${name} in ${stopWatch.elapsed}');
    stopWatch.stop();
  }

  @override
  Future<Set<Project>> get allProjects async {
    final List<Future<Project>> projectFutures = [];
    _addAll(projectFutures, this);
    return (await Future.wait(projectFutures)).toSet();
  }

  static void _addAll(List<Future<Project>> projects, ProjectGroup group) {
    projects.addAll(group.metaData.projects
        .map((p) => p.load(group.installDirectory.parent)));

    _addFromGroup(ProjectGroupRef ref) async {
      final g = await ref.load(group.installDirectory.parent);
      _addAll(projects, g);
    }
    group.metaData.childGroups.forEach(_addFromGroup);
  }

  @override
  Future processDependenciesDepthFirst(
      process(Project project, Iterable<Project> dependencies)) async {
    final projects = await allProjects;
    final DependencyGraph graph = await getDependencyGraph(projects);
    return graph.depthFirst(process);
  }
}

class ProjectImpl extends ProjectEntityImpl implements Project {
  PubSpec _pubspec;

  PubSpec get pubspec => _pubspec;

  String get name => pubspec.name;

  ProjectImpl(Uri gitUri, Directory installDirectory, this._pubspec)
      : super(gitUri, installDirectory);

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
    return initGitFlow(await gitDir);
  }

  @override
  Future featureStart(String featureName) async {
    _log.info('Starting feature $featureName for project ${name}');
    return gitFlowFeatureStart(await gitDir, featureName);
  }

  @override
  Future featureFinish(String featureName, {bool recursive: true}) async {
    _log.info('git flow feature finish $name for project ${name}');
    await gitFlowFeatureFinish(await gitDir, featureName);
  }

  @override
  Future setToPathDependencies(Iterable<Project> dependencies) async {
    _log.info('Setting up path dependencies for project ${name}');
    return _setDependencies(dependencies,
        (Project p) async => await new PathReference(p.installDirectory.path));
  }

  @override
  Future setToGitDependencies(Iterable<Project> dependencies) async {
    _log.info('Setting up git dependencies for project ${name}');
    return _setDependencies(dependencies, (Project p) async =>
        new GitReference(gitUri, await currentGitCommitHash));
  }

  Future<String> get currentGitCommitHash async =>
      currentCommitHash(await gitDir);

  Future _setDependencies(Iterable<Project> dependencies,
      Future<DependencyReference> createReferenceTo(Project p)) async {
    _log.info('Setting up dev dependencies for project ${name}');
    if (dependencies.isEmpty) {
      return;
    }

    final PubSpec _pubspec = await pubspec;
    final newDependencies = new Map.from(_pubspec.dependencies);

    dependencies.forEach((p) async {
      newDependencies[p.name] = createReferenceTo(p);
    });

    final newPubspec = _pubspec.copy(dependencies: newDependencies);
    await updatePubspec(newPubspec);
  }

  @override
  Future commit(String message) async {
    _log.info('Commiting project ${name} with message $message');
    return gitCommit(await gitDir, message);
  }

  @override
  Future push() async {
    _log.info('Pushing project ${name}');
    return gitPush(await gitDir);
  }

  @override
  Future pubGet() async {
    _log.info('Running pub get for project ${name}');
    final stopWatch = new Stopwatch()..start();
    await pubspec.get(installDirectory);
    _log.finest(
        'Completed pub get for project ${name} in ${stopWatch.elapsed}');
    stopWatch.stop();
  }
}

class ProjectGroupMetaDataImpl implements ProjectGroupMetaData {
  final String name;
  final Iterable<ProjectGroupRef> childGroups;
  final Iterable<ProjectRef> projects;

  ProjectGroupMetaDataImpl(this.name, this.childGroups, this.projects);
}

Future<ProjectGroup> loadProjectGroupFromInstallDirectory(
    Directory installDirectory) async {
//  print('========= $installDirectory');
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
//  print('=====+==== $installDirectory');
  final GitDir gitDir = await GitDir.fromExisting(installDirectory.path);

  final PubSpec pubspec = await PubSpec.load(installDirectory);

  final Uri gitUri = await getFirstRemote(gitDir);
  return new ProjectImpl(gitUri, installDirectory, pubspec);
}
