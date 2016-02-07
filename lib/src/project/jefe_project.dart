// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.jefe;

import 'package:jefe/src/project/project.dart';

/// A [Project] managed by Jefe
abstract class JefeProject extends Project {
  Set<JefeProject> get directDependencies;
  Set<JefeProject> get indirectDependencies;
  Set<JefeProject> get allDependencies;
}
