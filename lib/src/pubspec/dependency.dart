library devops.pubspec.dependency;

import 'package:pub_semver/pub_semver.dart';
import 'package:devops/src/jsonyaml/json_utils.dart';

abstract class DependencyReference extends Jsonable {
  DependencyReference();

  factory DependencyReference.fromJson(json) {
    if (json is Map) {
      if ((json as Map).length != 1) {
        throw new StateError('expecting only one entry for dependency');
      }
      switch (json.keys.first as String) {
        case 'path':
          return new PathReference.fromJson(json);
        case 'git':
          return new GitReference.fromJson(json);
        default:
          throw new StateError('unexpected dependency type ${json.keys.first}');
      }
    } else if (json is String) {
      return new HostedReference.fromJson(json);
    } else {
      throw new StateError('Unable to parse dependency $json');
    }
  }
}

class GitReference extends DependencyReference {
  final Uri url;
  final String ref;

  GitReference(this.url, this.ref);
  factory GitReference.fromJson(Map json) {
    final git = json['git'];
    if (git is String) {
      return new GitReference(Uri.parse(git), null);
    } else if (git is Map) {
      Map m = git;
      return new GitReference(Uri.parse(m['url']), m['ref']);
    } else {
      throw new StateError('Unexpected format for git dependency $git');
    }
  }

  @override
  Map toJson() => ref != null
      ? {'git': {'url': url.toString(), 'ref': ref}}
      : {'git': url.toString()};
}

class PathReference extends DependencyReference {
  final String path;

  PathReference(this.path);

  PathReference.fromJson(Map json) : this(json['path']);

  @override
  Map toJson() => {'path': path};
}

class HostedReference extends DependencyReference {
  final VersionConstraint versionConstraint;

  HostedReference(this.versionConstraint);

  HostedReference.fromJson(String json)
      : this(new VersionConstraint.parse(json));

  @override
  String toJson() => "'${versionConstraint.toString()}'";
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

//class Dependency extends Jsonable {
//  final String name;
//  final DependencyReference reference;
//
//  Dependency(this.name, this.reference);
//
//  @override
//  Map toJson() => {name: reference.toJson()};
//}
