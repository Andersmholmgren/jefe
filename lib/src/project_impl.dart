library devops.project.impl;
import 'dart:async';
import 'project.dart';

class ProjectImpl implements Project {
  final Iterable<Project> childProjects;
  final Iterable<Module> modules;

  ProjectImpl(this.childProjects, this.modules);

  @override
  Future install({bool recursive: true}) {
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