library devops.pub;

import 'package:devops/src/util/process_utils.dart';
import 'dart:async';
import 'dart:io';

Future get(Directory projectDirectory) =>
    runCommand('pub', ['get'], processWorkingDir: projectDirectory.path);
