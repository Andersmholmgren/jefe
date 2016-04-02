// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.intellij;

import 'dart:async';

import 'package:jefe/src/project/jefe_project.dart';
import 'package:path/path.dart' as p;
import 'package:quiver/check.dart';
import 'package:xml/xml.dart';

abstract class IntellijCommands extends JefeGroupCommand<IntellijCommands> {
  Future<IntellijVcsMappings> generateGitMappings(
      String intelliJProjectRootPath);
}

class IntellijVcsMapping {
  final String directory;
  final String vcs;
  static const String projectRootVariable = r'$PROJECT_DIR$';

  IntellijVcsMapping(String directory, String projectRootPath,
      {this.vcs: "Git"})
      : this.directory = toIntellijProjectDir(directory, projectRootPath) {
    checkNotNull(this.directory);
    checkNotNull(this.vcs);
  }

  static String toIntellijProjectDir(String directory, String projectRootPath) {
    final relative = p.relative(directory, from: projectRootPath);
    return p.join(projectRootVariable, relative);
  }

  XmlNode toXml() {
    return new XmlElement(new XmlName('mapping'), <XmlAttribute>[
      new XmlAttribute(new XmlName('directory'), directory),
      new XmlAttribute(new XmlName('vcs'), vcs)
    ], const []);
  }
}

class IntellijVcsMappings {
  final Iterable<IntellijVcsMapping> vcsDirectoryMappings;

  IntellijVcsMappings(this.vcsDirectoryMappings) {
    checkNotNull(this.vcsDirectoryMappings);
  }

  XmlNode toXml() {
    return new XmlElement(
        new XmlName('component'),
        <XmlAttribute>[
          new XmlAttribute(new XmlName('name'), 'VcsDirectoryMappings')
        ],
        vcsDirectoryMappings.map((m) => m.toXml()));
  }

  String toXmlString() =>
      new XmlDocument([_toWrappedXml()]).toXmlString(pretty: true);

  XmlNode _toWrappedXml() {
    return new XmlElement(
        new XmlName('project'),
        <XmlAttribute>[new XmlAttribute(new XmlName('version'), '4')],
        [toXml()]);
  }
}

