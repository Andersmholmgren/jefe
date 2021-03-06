// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.release.type;

import 'package:quiver/core.dart';
import 'package:pub_semver/pub_semver.dart';

typedef Version _VersionBumper(Version current);

Version _bumpMinor(Version v) => v.nextMinor;
Version _bumpMajor(Version v) => v.nextMajor;
Version _bumpPatch(Version v) => v.nextPatch;
Version _bumpBreaking(Version v) => v.nextBreaking;
Version _bumpLowest(Version v) {
  if (v.isPreRelease) {
    if (v.preRelease.length == 2 && v.preRelease[1] is int) {
      final int newPreReleaseNumber = v.preRelease[1] + 1;
      return new Version(v.major, v.minor, v.patch,
          pre: [v.preRelease[0], newPreReleaseNumber].join('.'));
    } else {
      throw new ArgumentError("Can't increment prerelease of ${v.preRelease}");
    }
  } else {
    return v.nextPatch;
  }
}

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

  static const ReleaseType lowest = const ReleaseType._(_bumpLowest, 'lowest');

  static final Set<ReleaseType> all =
      [major, minor, patch, breaking, lowest].toSet();

  /// Returns a new [Version] that adjusts [version] according to the type
  /// of release
  Version bump(Version version) => _bump(version);

  String toString() => _literal;

  static Optional<ReleaseType> fromLiteral(String str) =>
      Optional.fromNullable(all.firstWhere((t) => t._literal == str, orElse: () => null));
}
