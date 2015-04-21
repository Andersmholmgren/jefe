// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.group.impl;

import 'dart:async';
import '../project.dart';
import '../project_group.dart';
import 'dart:io';
import 'package:git/git.dart';
import '../../git/git.dart';
import 'package:quiver/iterables.dart';
import 'package:quiver/streams.dart' as streamz;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import '../dependency_graph.dart';
import '../../spec/jefe_spec.dart' as spec;
import 'project_impl.dart';
import '../../spec/jefe_spec.dart';
import 'core_impl.dart';

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
      {ProjectEntityReferenceFactory referenceFactory: const DefaultProjectEntityReferenceFactory()})
      : this.directoryLayout = directoryLayout,
        this._referenceFactory = referenceFactory,
        super(gitUri, directoryLayout.groupDirectory);

  static Future<ProjectGroup> install(Directory parentDir, String gitUri,
          {String name}) =>
      _installOrUpdate(parentDir, gitUri, name: name, updateIfExists: false);

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

    final String gitUri = await getFirstRemote(gitDir);
    return new ProjectGroupImpl(gitUri, results.elementAt(1), directoryLayout);
  }

  static Future<ProjectGroup> init(Directory parentDir, String gitUri,
          {String name}) =>
      _installOrUpdate(parentDir, gitUri, name: name, updateIfExists: true);

  static Future<ProjectGroup> _installOrUpdate(
      Directory parentDir, String gitUri,
      {String name, bool updateIfExists: true}) async {
    final workspaceName = name != null ? name : gitWorkspaceName(gitUri);
    _log.info('installing group $workspaceName from $gitUri into $parentDir');

    final GroupDirectoryLayout directoryLayout =
        new GroupDirectoryLayout.fromParent(parentDir, workspaceName);

    final onExistsAction =
        updateIfExists ? OnExistsAction.pull : OnExistsAction.ignore;

    final GitDir gitDir = await cloneOrPull(gitUri,
        directoryLayout.containerDirectory, directoryLayout.groupDirectory,
        onExistsAction);

    final spec.ProjectGroupMetaData metaData = await spec.ProjectGroupMetaData
        .fromDefaultProjectGroupYamlFile(gitDir.path);

    final projectGroup =
        new ProjectGroupImpl(gitUri, metaData, directoryLayout);

    final projectGroupInstallFutures = projectGroup.childGroups.map((ref) =>
        projectGroup._installChildGroup(ref.name, ref.gitUri, updateIfExists));
    final projectInstallFutures = projectGroup.projects.map(
        (ref) => projectGroup._installChildProject(
            ref.name, ref.gitUri, updateIfExists));
    await Future
        .wait(concat([projectGroupInstallFutures, projectInstallFutures]));

    _log.info(
        'Completed installing group $workspaceName from $gitUri into $parentDir');
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
      String name, String gitUri, bool updateIfExists) => _installOrUpdate(
          directoryLayout.containerDirectory, gitUri,
          name: name, updateIfExists: updateIfExists);

  Future<ProjectImpl> _installChildProject(
      String name, String gitUri, bool updateIfExists) => ProjectImpl.install(
          directoryLayout.containerDirectory, name, gitUri,
          updateIfExists: updateIfExists);

  @override
  Future<Set<Project>> get allProjects => _allProjectsStream.toSet();

  Stream<Project> get _allProjectsStream {
    final Stream<ProjectGroupImpl> childGroupStream =
        new Stream.fromIterable(childGroups.map((ref) => ref.get()))
            .asyncMap((pgf) => pgf);

    final Stream<Project> childProjectStream =
        childGroupStream.asyncExpand((pg) => pg._allProjectsStream);

    final Stream<Project> projectStream =
        new Stream.fromIterable(projects.map((p) => p.get()))
            .asyncMap((p) => p);

    final resultStream = streamz.concat([childProjectStream, projectStream]);

    return resultStream;
  }

  Future<DependencyGraph> get dependencyGraph async =>
      getDependencyGraph(await allProjects);

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

  GroupDirectoryLayout.withDefaultName(Directory containerDirectory) : this(
          containerDirectory.absolute,
          _defaultGroupName(containerDirectory.absolute));

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
          'Invalid container directory ($containerDirectory). '
          'Must start with $_containerSuffix');
    }

    return basename.replaceAll(_containerSuffix, '');
  }
}

Directory _childDir(Directory parent, String childName) =>
    new Directory(p.join(parent.path, childName));
