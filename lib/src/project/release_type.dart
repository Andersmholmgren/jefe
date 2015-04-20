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
  const ReleaseType._(this._bump);

  static const ReleaseType minor = const ReleaseType._(_bumpMinor);

  static const ReleaseType major = const ReleaseType._(_bumpMajor);

  static const ReleaseType patch = const ReleaseType._(_bumpPatch);

  static const ReleaseType breaking = const ReleaseType._(_bumpBreaking);

  /// Returns a new [Version] that adjusts [version] according to the type
  /// of release
  Version bump(Version version) => _bump(version);
}
