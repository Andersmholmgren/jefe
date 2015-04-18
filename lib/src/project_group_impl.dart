library devops.project.group.impl;

import 'dart:async';
import 'project.dart';
import 'dart:io';
import 'package:git/git.dart';
import 'package:devops/src/git/git.dart';
import 'package:quiver/iterables.dart';
import 'package:quiver/streams.dart' as streamz;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'dependency_graph.dart';
import 'package:devops/src/spec/JefeSpec.dart' as spec;
import 'package:devops/src/project_impl.dart';
import 'package:devops/src/spec/JefeSpec.dart';

Logger _log = new Logger('devops.project.group.impl');

class ProjectGroupReferenceImpl implements ProjectGroupReference {
  final ProjectGroupImpl parent;
  final spec.ProjectGroupIdentifier ref;
  ProjectGroupReferenceImpl(this.parent, this.ref);

  @override
  Future<ProjectGroup> get() => parent._getChildGroup(name, gitUri);

  @override
  String get gitUri => ref.gitUri;

  @override
  String get name => ref.name;
}

abstract class ProjectEntityReferenceFactory {
  ProjectGroupReference createGroupReference(
      ProjectGroupImpl group, ProjectGroupIdentifier id);
  ProjectReference createProjectReference(
      ProjectGroupImpl group, ProjectIdentifier id);
}

class DefaultProjectEntityReferenceFactory
    implements ProjectEntityReferenceFactory {
  const DefaultProjectEntityReferenceFactory();

  @override
  ProjectGroupReference createGroupReference(
          ProjectGroupImpl group, spec.ProjectGroupIdentifier id) =>
      new ProjectGroupReferenceImpl(group, id);

  @override
  ProjectReference createProjectReference(
          ProjectGroupImpl group, spec.ProjectIdentifier id) =>
      new ProjectReferenceImpl(group, id);
}

class ProjectGroupImpl extends ProjectEntityImpl implements ProjectGroup {
  // TODO: we need to hide the project group refs here etc as
  // it complicates encapsulating loading from the right directory

  final ProjectEntityReferenceFactory _referenceFactory;

  final spec.ProjectGroupMetaData metaData;
  String get name => metaData.name;

  final GroupDirectoryLayout directoryLayout;
  Directory get containerDirectory => directoryLayout.containerDirectory;

  ProjectGroupIdentifier get id => new ProjectGroupIdentifier(name, gitUri);

  Iterable<ProjectGroupReference> get _childGroups => metaData.childGroups
      .toSet()
      .map((gr) => _referenceFactory.createGroupReference(this, gr));

  Iterable<ProjectReference> get _projects => metaData.projects
      .toSet()
      .map((pr) => _referenceFactory.createProjectReference(this, pr));

  ProjectGroupImpl(
      String gitUri, this.metaData, GroupDirectoryLayout directoryLayout,
      {ProjectEntityReferenceFactory referenceFactory: const DefaultProjectEntityReferenceFactory()})
      : this.directoryLayout = directoryLayout,
        this._referenceFactory = referenceFactory,
        super(gitUri, directoryLayout.groupDirectory);

  static Future<ProjectGroup> install(Directory parentDir, String gitUri,
      {String name}) async {
    final workspaceName = name != null ? name : gitWorkspaceName(gitUri);
    _log.info('installing group $workspaceName from $gitUri into $parentDir');

    final GroupDirectoryLayout directoryLayout =
        new GroupDirectoryLayout.fromParent(parentDir, workspaceName);

    final Directory projectGroupRoot =
        await directoryLayout.containerDirectory.create(recursive: true);

    final GitDir gitDir = await clone(gitUri, projectGroupRoot);

    final spec.ProjectGroupMetaData metaData = await spec.ProjectGroupMetaData
        .fromDefaultProjectGroupYamlFile(gitDir.path);

    final projectGroup =
        new ProjectGroupImpl(gitUri, metaData, directoryLayout);

    final projectGroupInstallFutures = projectGroup._childGroups
        .map((ref) => projectGroup._installChildGroup(ref.name, ref.gitUri));
    final projectInstallFutures = projectGroup._projects
        .map((ref) => projectGroup._installChildProject(ref.name, ref.gitUri));
    await Future
        .wait(concat([projectGroupInstallFutures, projectInstallFutures]));

    return projectGroup;
  }

  static Future<ProjectGroup> load(Directory groupContainerDirectory) async {
    _log.info(
        'loading group from group container directory $groupContainerDirectory');
//  print('========= $installDirectory');
//    _childGr
    final directoryLayout =
        new GroupDirectoryLayout.withDefaultName(groupContainerDirectory);
    final groupDirectoryPath = directoryLayout.groupDirectory.path;

//    print('--- loading git dir from $groupDirectoryPath');
    final gitDirFuture = GitDir.fromExisting(groupDirectoryPath);
    final metaDataFuture = spec.ProjectGroupMetaData
        .fromDefaultProjectGroupYamlFile(groupDirectoryPath);
    final results = await Future.wait([gitDirFuture, metaDataFuture]);

    final GitDir gitDir = results.first;

    final String gitUri = await getFirstRemote(gitDir);
    return new ProjectGroupImpl(gitUri, results.elementAt(1), directoryLayout);
  }

  Future<ProjectGroupImpl> _getChildGroup(String childName, String gitUri) {
    final childContainer =
        directoryLayout.childGroup(childName).containerDirectory;
    _log.finer('loading child group $childName of $name contained in '
        '$childContainer. Parent container is $containerDirectory');

    return load(childContainer);
  }

  Future<ProjectImpl> getChildProject(String name, String gitUri) =>
      ProjectImpl.load(directoryLayout.projectDirectory(name));

  Future<ProjectGroupImpl> _installChildGroup(String name, String gitUri) =>
      install(directoryLayout.containerDirectory, gitUri, name: name);

  Future<ProjectImpl> _installChildProject(String name, String gitUri) =>
      ProjectImpl.install(directoryLayout.containerDirectory, name, gitUri);

  // parent is group container??
//  @deprecated
//  Directory _childGroupDirectory(String name, String gitUri) {
//    final container = _containerDirectory(gitUri, installDirectory.parent);
//    return new Directory(p.join(container.path, name));
//  }
//
//  Directory _childGroupDirectory2(String name) => _childDirectory(name);
//
//  Directory _childGroupContainerDirectory(String name, String gitUri) =>
//      _containerDirectory(gitUri, containerDirectory);

//  // parent is group container
//  Directory _childProjectDirectory(String name) => _childDirectory(name);
//
//  Directory _childDirectory(String name) =>
//      new Directory(p.join(containerDirectory.path, name));

  @override
  Future release({bool recursive: true, ReleaseType type: ReleaseType.minor}) {
    _log.info('Releasing all projects for group ${metaData.name} with release '
        'type $type');
    return processDependenciesDepthFirst((Project project,
        Iterable<Project> dependencies) => project.release(dependencies));
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
  Future<ProjectGroup> childProjectGroup(spec.ProjectGroupIdentifier ref) {
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
  Future initFlow({bool recursive: true}) =>
      _visitAllProjects('Initialising git flow', (p) => p.initFlow());

  @override
  Future featureStart(String name, {bool recursive: true}) => _visitAllProjects(
      'git flow feature start $name', (p) => p.featureStart(name));

  @override
  Future featureFinish(String name, {bool recursive: true}) =>
      _visitAllProjects(
          'git flow feature finish $name', (p) => p.featureFinish(name));

  @override
  Future releaseStart(String name, {bool recursive: true}) => _visitAllProjects(
      'git flow release start $name', (p) => p.releaseStart(name));

  @override
  Future releaseFinish(String name, {bool recursive: true}) =>
      _visitAllProjects(
          'git flow release finish $name', (p) => p.releaseFinish(name));

  @override
  Future pubGet() async {
    _log.info('Running pub get for group ${name}');
    final stopWatch = new Stopwatch()..start();

    await Future.wait((await allProjects).map((p) => p.pubGet()));
    _log.finest('Completed pub get for group ${name} in ${stopWatch.elapsed}');
    stopWatch.stop();
  }

//  @override
//  Future<Set<Project>> get projects => allProjects;

  @override
  Future<Set<Project>> get allProjects => _allProjectsStream.toSet();

  Stream<Project> get _allProjectsStream {
    final Stream<ProjectGroupImpl> childGroupStream =
        new Stream.fromIterable(_childGroups.map((ref) => ref.get()))
            .asyncMap((pgf) => pgf);

    final Stream<Project> childProjectStream =
        childGroupStream.asyncExpand((pg) => pg._allProjectsStream);

    final Stream<Project> projectStream =
        new Stream.fromIterable(_projects.map((p) => p.get()))
            .asyncMap((p) => p);

    final resultStream = streamz.concat([childProjectStream, projectStream]);

    return resultStream;
  }

  @override
  Future processDependenciesDepthFirst(
      process(Project project, Iterable<Project> dependencies)) async {
    final projects = await allProjects;
    final DependencyGraph graph = await getDependencyGraph(projects);
    return graph.processDepthFirst(process);
  }

  String toString() =>
      'ProjectGroup: $name; gitUri: $gitUri; installed: $installDirectory\n'
      '    projects: ${metaData.projects}\n'
      '    childGroups: ${metaData.childGroups}';

  @override
  Future visitAllProjects(process(Project project)) async {
//    _log.info('$taskDescription for group ${metaData.name}');
    await Future.wait((await allProjects).map((p) => process(p)));
  }

  Future _visitAllProjects(String taskDescription, process(Project p)) async {
    _log.info('$taskDescription for group ${metaData.name}');
    await Future.wait((await allProjects).map((p) => process(p)));
  }
}

class GroupDirectoryLayout {
  final Directory containerDirectory;
  final String groupName;

  GroupDirectoryLayout(this.containerDirectory, this.groupName);

  GroupDirectoryLayout.fromParent(Directory parent, String groupName)
      : this(_childDir(parent, _containerName(groupName)), groupName);

  GroupDirectoryLayout.withDefaultName(Directory containerDirectory)
      : this(containerDirectory, _defaultGroupName(containerDirectory));

  Directory get groupDirectory => _childDir(containerDirectory, groupName);

  Directory projectDirectory(String projectName) =>
      _childDir(containerDirectory, projectName);

  GroupDirectoryLayout childGroup(String childGroupName) =>
      new GroupDirectoryLayout.fromParent(containerDirectory, childGroupName);

  static const String _containerSuffix = '_root';

  static String _containerName(String groupName) =>
      groupName + _containerSuffix;

  static String _defaultGroupName(Directory containerDirectory) {
    final basename = p.basename(containerDirectory.path);
    if (!basename.endsWith(_containerSuffix)) {
      throw new ArgumentError(
          'Invalid container directory. Must start with $_containerSuffix');
    }

    return basename.replaceAll(_containerSuffix, '');
  }
}

Directory _childDir(Directory parent, String childName) =>
    new Directory(p.join(parent.path, childName));
