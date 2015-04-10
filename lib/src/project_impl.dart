library devops.project.impl;
import 'dart:async';
import 'project.dart';
import 'dart:io';
import 'package:git/git.dart';

class ProjectRefImpl implements ProjectRef {
  @override
  final Uri gitUri;

  ProjectRefImpl(this.gitUri);

  @override
  Future<Project> fetch() {

    // TODO: implement fetch
  }



}

class ProjectImpl implements Project {
  @override
  final String name;

  final Iterable<ProjectRef> childProjects;
  final Iterable<ModuleRef> modules;

  ProjectImpl(this.name, this.childProjects, this.modules);

  @override
  Future install(Directory parentDir, {bool recursive: true}) {
    // TODO: implement install
  }

  @override
  Future release({bool recursive: true}) {
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

}

class ModuleImpl implements Module {

}