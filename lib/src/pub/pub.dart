// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.pub;

import '../util/process_utils.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:jefe/src/pub/pub_version.dart';
import 'package:option/option.dart';
import 'dart:convert';
import 'package:path/path.dart' as p;

Future get(Directory projectDirectory) =>
    runCommand('pub', ['get'], processWorkingDir: projectDirectory.path);

Future test(Directory projectDirectory) async {
  if (await new Directory(p.join(projectDirectory.path, 'test')).exists()) {
    return runCommand('pub', ['run', 'test'],
        processWorkingDir: projectDirectory.path);
  }
}

Future publish(Directory projectDirectory) =>
    runCommand('pub', ['publish', '--force'],
        processWorkingDir: projectDirectory.path);

Future<Option<HostedPackageVersions>> fetchPackageVersions(
    String packageName, {Uri publishToUrl}) async {
  final baseUrl = publishToUrl?.toString() ?? 'https://pub.dartlang.org';

  final http.Response response =
      await http.get('$baseUrl/api/packages/$packageName');

  switch (response.statusCode) {
    case 200:
      return new Some(
          new HostedPackageVersions.fromJson(JSON.decode(response.body)));

    case 404:
      return const None();

    default:
      throw new StateError('unexpected status code ${response.statusCode}');
  }
}
