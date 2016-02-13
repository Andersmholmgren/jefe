// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.commands.pub;

import 'dart:async';

abstract class PubCommands {
  Future get();

  Future publish();

  Future fetchPackageVersions();

  Future test();
}
