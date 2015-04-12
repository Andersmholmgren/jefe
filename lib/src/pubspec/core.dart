library devops.pubspec.core;

import 'package:pub_semver/pub_semver.dart';

abstract class Yamlable {
  toYaml();
}
