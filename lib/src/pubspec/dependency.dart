library devops.pubspec.dependency;

import 'package:pub_semver/pub_semver.dart';
import 'package:devops/src/pubspec/core.dart';

class Dependency extends Yamlable {
  final String name;
  final DependencyReference reference;

  Dependency(this.name, this.reference);

  @override
  Map toYaml() => {name: reference.toYaml()};
}

abstract class DependencyReference extends Yamlable {}

class GitReference extends DependencyReference {
  final Uri url;
  final String ref;

  GitReference(this.url, this.ref);

  @override
  Map toYaml() => {'url': url.toString(), 'ref': ref};
}

class PathReference extends DependencyReference {
  final String path;

  PathReference(this.path);

  @override
  Map toYaml() => {'path': path};
}

class HostedReference extends DependencyReference {
  final VersionConstraint versionConstraint;

  HostedReference(this.versionConstraint);

  @override
  String toYaml() => versionConstraint.toString();
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
