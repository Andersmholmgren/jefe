library devops.pubspec.dependency;

import 'package:pub_semver/pub_semver.dart';
import 'package:devops/src/jsonyaml/json_utils.dart';

class Dependency extends Jsonable {
  final String name;
  final DependencyReference reference;

  Dependency(this.name, this.reference);
  factory Dependency.fromJson(Map json) {
    final p = parseJson(json);
    return new Dependency(p.single('name'), p.single('ref'));
  }

  @override
  Map toJson() => {name: reference.toJson()};
}

abstract class DependencyReference extends Jsonable {}

class GitReference extends DependencyReference {
  final Uri url;
  final String ref;

  GitReference(this.url, this.ref);

  @override
  Map toJson() => {'url': url.toString(), 'ref': ref};
}

class PathReference extends DependencyReference {
  final String path;

  PathReference(this.path);

  @override
  Map toJson() => {'path': path};
}

class HostedReference extends DependencyReference {
  final VersionConstraint versionConstraint;

  HostedReference(this.versionConstraint);

  @override
  String toJson() => versionConstraint.toString();
}

//VersionConstraint

/*
  frentity:
    git:
      url: https://bitbucket.org/andersmholmgren/frentity.git
      ref: 0980b2a
  gissue_common:
    path: ../gissue_common

 */
