library dockerfile.spec;

import 'package:devops/src/jsonyaml/json_utils.dart';
import 'dart:async';
import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;
import 'package:devops/src/yaml/yaml_writer.dart';

const String _standardFileName = 'Dockerfile';

class Dockerfile implements Jsonable {
  final String name;

  final Map unParsedYaml;

  Dockerfile({this.name, this.unParsedYaml});

  factory Dockerfile.fromJson(Map json) {
    final p = parseJson(json, consumeMap: true);
    return new Dockerfile(name: p.single('name'), unParsedYaml: p.unconsumed);
  }

  static Future<Dockerfile> load(Directory projectDirectory) async =>
      new Dockerfile.fromJson(loadYaml(
          await new File(p.join(projectDirectory.path, _standardFileName))
              .readAsString()));

  Dockerfile copy({String name, Map unParsedYaml}) {
    return new Dockerfile(
        name: name != null ? name : this.name,
        unParsedYaml: unParsedYaml != null ? unParsedYaml : this.unParsedYaml);
  }

  @override
  Map toJson() {
    return (buildJson
      ..add('name', name)
      ..addAll(unParsedYaml)).json;
  }

  Future save(Directory parentDir) {
    final ioSink =
        new File(p.join(parentDir.path, _standardFileName)).openWrite();
    try {
      writeYamlString(toJson(), ioSink);
    } finally {
      return ioSink.close();
    }
  }
}
