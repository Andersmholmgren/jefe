library devops.pubspec;

import 'package:pub_semver/pub_semver.dart';
import 'package:devops/src/pubspec/dependency.dart';
import 'package:devops/src/jsonyaml/json_utils.dart';
import 'dart:async';
import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

class PubSpec implements Jsonable {
  final String name;

  final String author;

  final Version version;

  final String homepage;

  final String documentation;

  final String description;

//  VersionConstraint sdkConstraint;

  final Map<String, DependencyReference> dependencies;

  final Map<String, DependencyReference> devDependencies;

  final Map<String, DependencyReference> dependencyOverrides;

  final Map unParsedYaml;

  PubSpec({this.name, this.author, this.version, this.homepage,
      this.documentation, this.description, this.dependencies,
      this.devDependencies, this.dependencyOverrides, this.unParsedYaml});

  factory PubSpec.fromJson(Map json) {
    final p = parseJson(json, consumeMap: true);
    return new PubSpec(
        name: p.single('name'),
        author: p.single('author'),
        version: p.single('version', (v) => new Version.parse(v)),
        homepage: p.single('homepage'),
        documentation: p.single('documentation'),
        description: p.single('description'),
        dependencies: p.mapValues(
            'dependencies', (v) => new DependencyReference.fromJson(v)),
        devDependencies: p.mapValues(
            'dev_dependencies', (v) => new DependencyReference.fromJson(v)),
        dependencyOverrides: p.mapValues(
            'dependency_overrides', (v) => new DependencyReference.fromJson(v)),
        unParsedYaml: p.unconsumed);
  }

  static Future<PubSpec> load(Directory parentDir) async =>
      new PubSpec.fromJson(loadYaml(
          await new File(p.join(parentDir.path, 'pubspec.yaml'))
              .readAsString()));

  PubSpec copy({String name, String author, Version version, String homepage,
      String documentation, String description,
      Map<String, DependencyReference> dependencies,
      Map<String, DependencyReference> devDependencies,
      Map<String, DependencyReference> dependencyOverrides, Map unParsedYaml}) {
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
      ..add('dev_dependencies', devDependencies)
      ..add('dependency_overrides', dependencyOverrides)
      ..addAll(unParsedYaml)).json;
  }
}
