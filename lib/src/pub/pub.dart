library jefe.pub;

import '../util/process_utils.dart';
import 'dart:async';
import 'dart:io';

Future get(Directory projectDirectory) =>
    runCommand('pub', ['get'], processWorkingDir: projectDirectory.path);
