// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.pub.version;

import 'package:jefe/src/jsonyaml/json_utils.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec/pubspec.dart';

class PubVersion {
  final Uri archiveUrl;

  final PubSpec pubSpec;

  final Version version;

  PubVersion(this.archiveUrl, this.pubSpec, this.version);

  factory PubVersion.fromJson(Map json) {
    final p = parseJson(json);
    final archiveUrl = p.single('archive_url', (v) => Uri.parse(v));
    final pubSpec = p.single('pubspec', (v) => new PubSpec.fromJson(v));
    final version = p.single('version', (v) => new Version.parse(v));
    return new PubVersion(archiveUrl, pubSpec, version);
  }
}

class HostedPackageVersions {
  final String packageName;

  final PubVersion latest;

  final Iterable<PubVersion> versions;

  HostedPackageVersions(this.packageName, this.latest, this.versions);

  factory HostedPackageVersions.fromJson(Map json) {
    final p = parseJson(json);
    final packageName = p.single('name');
    final latest = p.single('latest', (v) => new PubVersion.fromJson(v));
    final versions = p.list('versions', (v) => new PubVersion.fromJson(v));

    return new HostedPackageVersions(packageName, latest, versions);
  }
}
