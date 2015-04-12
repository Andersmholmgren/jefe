library devops.pubspec;

import 'package:pub_semver/pub_semver.dart';
import 'package:devops/src/pubspec/dependency.dart';
import 'package:devops/src/pubspec/core.dart';

class PubSpec implements Yamlable {
  final String name;

  final String author;

  final Version version;

  final String homepage;

  final String documentation;

  final String description;

//  VersionConstraint sdkConstraint;

  final Map<String, Dependency> dependencies;

  final Map<String, Dependency> devDependencies;

  final Map<String, Dependency> dependencyOverrides;

  final Map unParsedYaml;

  PubSpec({this.name, this.author, this.version, this.homepage,
      this.documentation, this.description, this.dependencies,
      this.devDependencies, this.dependencyOverrides, this.unParsedYaml});

  PubSpec copy({String name, String author, Version version, String homepage,
      String documentation, String description,
      Map<String, Dependency> dependencies,
      Map<String, Dependency> devDependencies,
      Map<String, Dependency> dependencyOverrides, Map unParsedYaml}) {
    return new PubSpec(
        name: name != null ? name : this.name,
        author: author != null ? author : this.author,
        version: version != null ? version : this.version,
        homepage: homepage != null ? homepage : this.homepage,
        documentation: documentation != null
            ? documentation
            : this.documentation,
        description: description != null ? description : this.description,
        dependencies: dependencies != null ? dependencies : this.dependencies,
        devDependencies: devDependencies != null
            ? devDependencies
            : this.devDependencies,
        dependencyOverrides: dependencyOverrides != null
            ? dependencyOverrides
            : this.dependencyOverrides,
        unParsedYaml: unParsedYaml != null ? unParsedYaml : this.unParsedYaml);
  }

  @override
  Map toYaml() {
    final map = {};
    _add(map, 'name', name);
    _add(map, 'author', author);
    _add(map, 'version', version);
    _add(map, 'homepage', homepage);
    _add(map, 'documentation', documentation);
    _add(map, 'description', description);
    _add(map, 'dependencies', dependencies);
    _add(map, 'devDependencies', devDependencies);
    _add(map, 'dependencyOverrides', dependencyOverrides);
    _add(map, 'unParsedYaml', unParsedYaml);
    return map;
  }
}

void _add(Map yaml, String key, value, [transform(v)]) {
  if (value != null) {
    yaml[key] = _transformValue(value, transform);
  }
}

_transformValue(value, transform(v)) {
  if (transform != null) {
    return transform(value);
  }
  if (value is Yamlable) {
    return value.toYaml();
  }
  if (value is Map) {
    final result = {};
    (value as Map).forEach((k, v) {
      result[k] = _transformValue(value, null);
    });
    return result;
  }
  if (value is Iterable) {
    return (value as Iterable).map((v) => _transformValue(v, null)).toList();
  }
  return value;
}
