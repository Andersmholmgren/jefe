// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.group.impl;

import 'dart:async';
import 'dart:io';

import 'package:git/git.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:quiver/iterables.dart';
import 'package:quiver/streams.dart' as streamz;

import '../../git/git.dart';
import '../../spec/jefe_spec.dart' as spec;
import '../../spec/jefe_spec.dart';
import '../dependency_graph.dart';
import '../project.dart';
import '../project_group.dart';
import 'core_impl.dart';
import 'project_impl.dart';
import 'package:option/option.dart';

Logger _log = new Logger('jefe.project.group.impl');

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

  Iterable<ProjectGroupReference> get childGroups => metaData.childGroups
      .toSet()
      .map((gr) => _referenceFactory.createGroupReference(this, gr));

  Iterable<ProjectReference> get projects => metaData.projects
      .toSet()
      .map((pr) => _referenceFactory.createProjectReference(this, pr));

  ProjectGroupImpl(
      String gitUri, this.metaData, GroupDirectoryLayout directoryLayout,
      {ProjectEntityReferenceFactory referenceFactory:
          const DefaultProjectEntityReferenceFactory()})
      : this.directoryLayout = directoryLayout,
        this._referenceFactory = referenceFactory,
        super(gitUri, directoryLayout.groupDirectory);

  static Future<ProjectGroup> install(Directory parentDir, String gitUri,
          {String name}) =>
      _installOrUpdate(parentDir, gitUri, name: name, updateIfExists: true);

  static Future<ProjectGroup> load(Directory groupContainerDirectory) async {
    _log.fine(
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

    final String gitUri = await getOriginOrFirstRemote(gitDir);
    return new ProjectGroupImpl(gitUri, results.elementAt(1), directoryLayout);
  }

  static Future<ProjectGroup> init(Directory parentDir, String gitUri,
          {String name}) =>
      _installOrUpdate(parentDir, gitUri, name: name, updateIfExists: true);

  static Future<Directory> jefetize(Directory parentDirectory) async {
    Future<Directory> massageContainerDirectory() async {
      if (!parentDirectory.path
          .endsWith(GroupDirectoryLayout._containerSuffix)) {
        final containerPath =
            parentDirectory.path + GroupDirectoryLayout._containerSuffix;
        final containerDirectory = await parentDirectory.rename(containerPath);
        _log.warning("moving project container to $containerDirectory");
        return containerDirectory;
      } else {
        return parentDirectory;
      }
    }

    final containerDirectory = await massageContainerDirectory();
    final layout = new GroupDirectoryLayout.withDefaultName(containerDirectory);

    await layout.groupDirectory.create(recursive: true);

    final projects = await _projectSubDirectories(containerDirectory)
        .asyncMap(Project.load)
        .toSet() as Set<Project>;

    print(projects);
//    new ProjectGroupImpl()

    final metaData = new ProjectGroupMetaData(
        p.basename(parentDirectory.path), const [], projects.map((p) => p.id));

    await metaData.save(layout.groupDirectory);

    return layout.containerDirectory;

//    final groupDir
  }

  static Future<ProjectGroup> _installOrUpdate(Directory dir, String gitUri,
      {String name, bool updateIfExists: true}) async {
    _log.info(
        'initialising group with gitUri: $gitUri and installDirectory: $dir');

    final GroupDirectoryLayout directoryLayout =
        await GroupDirectoryLayout.resolve(dir, gitUri);

    final onExistsAction =
        updateIfExists ? OnExistsAction.pull : OnExistsAction.ignore;

    final Directory projectGroupRoot =
        await directoryLayout.containerDirectory.create(recursive: true);

    await cloneOrPull(gitUri, projectGroupRoot, directoryLayout.groupDirectory,
        onExistsAction);

//    final spec.ProjectGroupMetaData metaData = await spec.ProjectGroupMetaData
//        .fromDefaultProjectGroupYamlFile(gitDir.path);

    final projectGroup =
        await load(directoryLayout.containerDirectory) as ProjectGroupImpl;
//        new ProjectGroupImpl(gitUri, metaData, directoryLayout);

    final projectGroupInstallFutures = projectGroup.childGroups.map((ref) =>
        projectGroup._installChildGroup(ref.name, ref.gitUri, updateIfExists));
    final projectInstallFutures = projectGroup.projects.map((ref) =>
        projectGroup._installChildProject(
            ref.name, ref.gitUri, updateIfExists));
    await Future.wait(concat(<Iterable<Future>>[
      projectGroupInstallFutures,
      projectInstallFutures
    ]) as Iterable<Future>);

    _log.info('Completed initialising group with gitUri: $gitUri and '
        'installDirectory: $dir');

    return projectGroup;
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

  Future<ProjectGroupImpl> _installChildGroup(
          String name, String gitUri, bool updateIfExists) =>
      _installOrUpdate(directoryLayout.containerDirectory, gitUri,
          name: name, updateIfExists: updateIfExists);

  Future<ProjectImpl> _installChildProject(
          String name, String gitUri, bool updateIfExists) =>
      ProjectImpl.install(directoryLayout.containerDirectory, name, gitUri,
          updateIfExists: updateIfExists);

  @override
  Future<Set<Project>> get allProjects => _allProjectsStream.toSet();

  Stream<Project> get _allProjectsStream {
    final Stream<ProjectGroupImpl> childGroupStream =
        new Stream<Future<ProjectGroup>>.fromIterable(
                childGroups.map/*<Future<ProjectGroup>>*/((ref) => ref.get()))
            .asyncMap((pgf) => pgf) as Stream<ProjectGroupImpl>;

    final Stream<Project> childProjectStream = childGroupStream
        .asyncExpand((pg) => pg._allProjectsStream) as Stream<Project>;

    final Stream<Project> projectStream =
        new Stream<Future<Project>>.fromIterable(projects.map((p) => p.get()))
            .asyncMap((p) => p) as Stream<Project>;

    final resultStream = streamz.concat([childProjectStream, projectStream]);

    return resultStream as Stream<Project>;
  }

  @deprecated
  Future<JefeProjectSet> get dependencyGraph => rootJefeProjects;

  Future<JefeProjectSet> get rootJefeProjects async =>
      getRootProjects(await allProjects, containerDirectory);

  String toString() =>
      'ProjectGroup: $name; gitUri: $gitUri; installed: $installDirectory\n'
      '    projects: ${metaData.projects}\n'
      '    childGroups: ${metaData.childGroups}';
}

class GroupDirectoryLayout {
  final Directory containerDirectory;
  final String groupName;

  GroupDirectoryLayout(this.containerDirectory, this.groupName);

  GroupDirectoryLayout.fromParent(Directory parent, String groupName)
      : this(_childDir(parent, _containerName(groupName)), groupName);

  GroupDirectoryLayout.withDefaultName(Directory containerDirectory)
      : this(containerDirectory.absolute,
            _defaultGroupName(containerDirectory.absolute));

  Directory get groupDirectory => _childDir(containerDirectory, groupName);

  Directory projectDirectory(String projectName) =>
      _childDir(containerDirectory, projectName);

  GroupDirectoryLayout childGroup(String childGroupName) =>
      new GroupDirectoryLayout.fromParent(containerDirectory, childGroupName);

  static const String _containerSuffix = ProjectGroup.containerSuffix;

  static String _containerName(String groupName) =>
      groupName + _containerSuffix;

  static String _defaultGroupName(Directory containerDirectory) {
    final basename = p.basename(containerDirectory.path);
    if (!basename.endsWith(_containerSuffix)) {
      throw new ArgumentError(
          'Invalid container directory ($containerDirectory). '
          'Must start with $_containerSuffix');
    }

    return basename.replaceAll(_containerSuffix, '');
  }

  static Future<GroupDirectoryLayout> resolve(
      Directory directory, String gitUri) async {
    // TODO: should check if gitUri is the uri for the current group too
    final _directory = _tweakDirectory(directory);

    if (gitUri == null) {
      if (await isExistingContainerDirectory(_directory)) {
        return new GroupDirectoryLayout.withDefaultName(_directory);
      } else {
        throw new ArgumentError('must either be in a container directory or '
            'specify a gitUri');
      }
    } else {
      return new GroupDirectoryLayout.fromParent(
          _directory, gitWorkspaceName(gitUri));
    }
  }

  static Future<bool> isExistingContainerDirectory(Directory directory) async {
    bool looksLikeAContainer = (await directory.exists() &&
        p.basename(directory.path).endsWith(_containerSuffix));

    if (!looksLikeAContainer) {
      _log.finest(
          "$directory is not an existing directory ending with $_containerSuffix");
      return false;
    }

    final groupName = _defaultGroupName(directory);

    final Directory groupDirectory = _childDir(directory, groupName);
    bool smellsLikeAContainer = await groupDirectory.exists();

    if (!smellsLikeAContainer) {
      _log.finest("$directory does not have an existing group directory called "
          "$groupName");
      return false;
    }

    final jefeSpecFile = new File(p.join(groupDirectory.path, 'jefe.yaml'));
    bool isAContainer = await jefeSpecFile.exists();
    if (!isAContainer) {
      _log.finest("$jefeSpecFile does not exist");
    }

    return isAContainer;
  }
}

Directory _childDir(Directory parent, String childName) =>
    new Directory(p.join(parent.path, childName));

Directory _tweakDirectory(Directory directory) => _toDirectory(directory.path);

Directory _toDirectory(String path) =>
    path == '.' ? Directory.current : new Directory(path);

Stream<Directory> _projectSubDirectories(Directory parentDirectory) {
  return parentDirectory
      .list(followLinks: false)
      .where((e) => e is Directory)
      .asyncMap((e) async {
        var file = new File(p.join(e.path, 'pubspec.yaml'));
        print('checking if exists on $file');
        return await file.exists() ? new Some(e) : const None();
      })
      .where((o) => o is Some)
      .map((o) => o.get());
}
