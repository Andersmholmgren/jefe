// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:devops/devops.dart' as devops;

main() {
  print('Hello world: ${devops.calculate()}!');
}


/*
release process

1/ create release

> grind release-build

create release branch (git flow release)
- in gitbacklog
- in gissue

complete gissue release & push

update gitbacklog dependency to be git dependency
- requires ssh keys in docker

2/ run locally

> grind run -v 0.10.2.1234125

checkouts out tag (0.10.2.1234125) of gitbacklog

gcloud run w/o pubserve

3/ deploy release

> grind release-deploy [-v 0.10.2.1234125]

if version specified checkout that tag

gcloud deploy



========

Dev layout

project.yaml (maybe at the backlogio level + gissue + gitbacklog)
- generates pubspec.yaml
- handles local paths for dev as overrides



- backlogio project.yaml

  projects:
  	gissue: https://github.com/Andersmholmgren/gissue
  	gitbacklog: https://github.com/Andersmholmgren/gissue


OR

- gitbacklog project.yaml (https://github.com/Andersmholmgren/gitbacklog)

  modules:
	  gitbacklog_client: https://github.com/Andersmholmgren/gitbacklog_client
	  gitbacklog_server: https://github.com/Andersmholmgren/gitbacklog_server

  projects:
    gissue: https://github.com/Andersmholmgren/gissue


- gissue project.yaml

  modules:
	  gissue_common: https://github.com/Andersmholmgren/gissue_common


run> devops dev

- creates overrides like

  dep_overrides:
  	  gissue_common:
  	  	path: ../gissue_common in relevant pubspecs


run> devops release

- bumps minor version on all changed projects (in order)
- git releases them with tag
- changes all dependencies to be git dependencies based on tag / hash

Note: needs to figure out dependency graph for that (of project / modules only) and run in order


---
Commands

devops install
devops dev
devops release
devops update  // to update the project.yaml files

Maybe export grinder tasks too



---
backlog project layout


 */