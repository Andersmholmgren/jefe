// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.release.type;

import 'package:pub_semver/pub_semver.dart';

typedef Version _VersionBumper(Version current);

Version _bumpMinor(Version v) => v.nextMinor;
Version _bumpMajor(Version v) => v.nextMajor;
Version _bumpPatch(Version v) => v.nextPatch;
Version _bumpBreaking(Version v) => v.nextBreaking;

/// Identifies a type of release
class ReleaseType {
  final _VersionBumper _bump;
  final String _literal;

  const ReleaseType._(this._bump, this._literal);

  static const ReleaseType minor = const ReleaseType._(_bumpMinor, 'minor');

  static const ReleaseType major = const ReleaseType._(_bumpMajor, 'major');

  static const ReleaseType patch = const ReleaseType._(_bumpPatch, 'patch');

  static const ReleaseType breaking =
      const ReleaseType._(_bumpBreaking, 'breaking');

  /// Returns a new [Version] that adjusts [version] according to the type
  /// of release
  Version bump(Version version) => _bump(version);

  String toString() => _literal;
}
