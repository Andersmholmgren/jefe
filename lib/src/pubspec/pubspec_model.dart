library devops.pubspec;

import 'package:pub_semver/pub_semver.dart';
import 'package:devops/src/pubspec/dependency.dart';
import 'package:devops/src/jsonyaml/json_utils.dart';

class PubSpec implements Jsonable {
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

  factory PubSpec.fromJson(Map json) {
    final p = parseJson(json);
    return new PubSpec(
        name: p.single('name'),
        author: p.single('author'),
        version: p.single('version', (v) => new Version.parse(v)),
        homepage: p.single('homepage'),
        documentation: p.single('documentation'),
        description: p.single('description'),
        dependencies: p.mapValues(
            'dependencies', (v) => new Dependency.fromJson(v)),
        unParsedYaml: p.unconsumed);
  }

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
  Map toJson() {
    return (buildJson
      ..add('name', name)
      ..add('author', author)
      ..add('version', version)
      ..add('homepage', homepage)
      ..add('documentation', documentation)
      ..add('description', description)
      ..add('dependencies', dependencies)
      ..add('devDependencies', devDependencies)
      ..add('dependencyOverrides', dependencyOverrides)
      ..add('unParsedYaml', unParsedYaml)).json;
  }
}
