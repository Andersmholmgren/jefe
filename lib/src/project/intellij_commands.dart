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
    return (new XmlBuilder()
          ..element("mapping",
              attributes: <String, String>{'directory': directory, 'vcs': vcs}))
        .build();
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
}

/*
<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="VcsDirectoryMappings">
    <mapping directory="$PROJECT_DIR$/dockerfile" vcs="Git" />
    <mapping directory="$PROJECT_DIR$/jefe" vcs="Git" />
    <mapping directory="$PROJECT_DIR$/jefe_container" vcs="Git" />
    <mapping directory="$PROJECT_DIR$/pubspec" vcs="Git" />
    <mapping directory="$PROJECT_DIR$/stuff" vcs="Git" />
    <mapping directory="$PROJECT_DIR$/yamlicious" vcs="Git" />
  </component>
</project>
 */
