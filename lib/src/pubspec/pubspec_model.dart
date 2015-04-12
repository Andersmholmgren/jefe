library devops.pubspec;

import 'package:pub_semver/pub_semver.dart';
import 'package:devops/src/pubspec/dependency.dart';
import 'package:devops/src/jsonyaml/json_utils.dart';
import 'dart:async';
import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;
import 'package:devops/src/yaml/yaml_writer.dart';

class PubSpec implements Jsonable {
  final String name;

  final String author;

  final Version version;

  final String homepage;

  final String documentation;

  final String description;

  final Environment environment;

  final Map<String, DependencyReference> dependencies;

  final Map<String, DependencyReference> devDependencies;

  final Map<String, DependencyReference> dependencyOverrides;

  final Map unParsedYaml;

  PubSpec({this.name, this.author, this.version, this.homepage,
      this.documentation, this.description, this.environment, this.dependencies,
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
        environment: p.single(
            'environment', (v) => new Environment.fromJson(v)),
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
      String documentation, String description, Environment environment,
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
        environment: environment != null ? environment : this.environment,
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
      ..add('environment', environment)
      ..add('description', description)
      ..add('dependencies', dependencies)
      ..add('dev_dependencies', devDependencies)
      ..add('dependency_overrides', dependencyOverrides)
      ..addAll(unParsedYaml)).json;
  }

  Future save(Directory parentDir) {
    final ioSink = new File(p.join(parentDir.path, 'pubspec.yaml')).openWrite();
    try {
      writeYamlString(toJson(), ioSink);
    } finally {
      return ioSink.close();
    }
  }
}

class Environment implements Jsonable {
  final VersionConstraint sdkConstraint;
  final Map unParsedYaml;

  Environment(this.sdkConstraint, this.unParsedYaml);

  factory Environment.fromJson(Map json) {
    final p = parseJson(json, consumeMap: true);
    return new Environment(
        p.single('sdk', (v) => new VersionConstraint.parse(v)), p.unconsumed);
  }

  @override
  Map toJson() {
    return (buildJson
      ..add('sdk', "'${sdkConstraint.toString()}'")
      ..addAll(unParsedYaml)).json;
  }
}
