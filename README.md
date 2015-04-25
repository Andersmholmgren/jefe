# jefe

A library for maintaining sets of related Dart projects versioned in git, in particular managing dependencies between them.

## Usage

For now the best place to learn about Jefe is the 
[introductory blog post](http://backlogio.blogspot.com/2015/04/managing-your-dart-projects-like-jefe.html).

Jefe is designed to be used both as a command (called `jefe`) and as source (e.g. integrating with other tools like grinder)

### Installing


```
pub global activate jefe
```


### Project Lifecycle Basics

```

import 'package:jefe/jefe.dart';


main() async {
  // first install the project group
  final ProjectGroup projectGroup = await ProjectGroup.install(
      new Directory('/Users/blah'), 'git@git.example');

  final executor = new CommandExecutor(projectGroup);

  // initialise it (sets it on develop branch etc)
  await executor.executeAll(lifecycle.init());

  // start a new feature
  // All projects will be on a feature branch called feacha,
  // will have the dependencies to other projects in this group set as
  // path dependencies, and will have pub get called
  await executor.executeAll(lifecycle.startNewFeature('feacha'));

  // Code something awesome

  // finish off the feature
  // All projects will have their feature branches merged to develop,
  // will have the dependencies to other projects in this group set as
  // git dependencies bashed on the current commit hash,
  // will be git pushed to their origin
  // and will have pub get called
  await executor.execute(lifecycle.completeFeature('feacha'));

  // now cut a release.
  // All the project pubspec versions will be bumped according to the release type
  // and git tagged with same version, will be merged to master
  await executor.execute(lifecycle.release(type: ReleaseType.major));
}

```

### Generate a Production Dockerfile

```

main() async {
  final executor = await executorForDirectory('/Users/blah/myfoo_root');

  await executor.executeOnGraph(docker.generateProductionDockerfile(
      'my_server', 'my_client',
      outputDirectory: new Directory('/tmp'),
      dartVersion: '1.9.3',
      environment: {'MY_FOO': false},
      exposePorts: [8080, 8181, 5858],
      entryPointOptions: ["--debug:5858/0.0.0.0"]));
}


```


## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/Andersmholmgren/jefe/issues
