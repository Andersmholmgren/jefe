import 'package:unscripted/unscripted.dart';
import 'dart:io';
import 'package:devops/devops.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'package:stack_trace/stack_trace.dart';

main(arguments) {
  Chain.capture(() {
    new Script(Jefe).execute(arguments);
  }, onError: (error, stackChain) {
    print("Caught error $error\n"
        "${stackChain.terse}");
  });
}

class Jefe {
  final lifecycle = new ProjectLifecycle();
  final process = new ProcessCommands();

  @Command(
      help: 'Manages a set of related Dart projects',
      plugins: const [const Completion()])
  Jefe() {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((cr) {
      print('${cr.time}: ${cr.message}');
    });
    hierarchicalLoggingEnabled = true;
  }

  @SubCommand(help: 'Installs a group of projects')
  install(@Positional(
      help: 'The git Uri containing the project.yaml.') String gitUri, {@Option(
      help: 'The directory to install into',
      abbr: 'd') String installDirectory: '.'}) async {
    final Directory installDir = new Directory(installDirectory);
    final ProjectGroup projectGroup =
        await ProjectGroup.install(installDir, gitUri);

    final executor = new CommandExecutor(projectGroup);
    await executor.executeAll(lifecycle.init());
  }

  @SubCommand(help: 'Sets up for the start of development on a new feature')
  start(String featureName, {@Option(
      help: 'The directory that contains the root of the projecs',
      abbr: 'd') String rootDirectory: '.'}) async {
    final executor = await load(rootDirectory);
    await executor.executeAll(lifecycle.startNewFeature(featureName));
  }

  @SubCommand(help: 'Completes feature and returns to development branch')
  finish(String featureName, {@Option(
      help: 'The directory that contains the root of the projecs',
      abbr: 'd') String rootDirectory: '.'}) async {
    final executor = await load(rootDirectory);
    await executor.execute(lifecycle.completeFeature(featureName));
  }

  @SubCommand(help: 'Create a release of all the projects')
  release({@Option(
      help: 'The directory that contains the root of the projecs',
      abbr: 'd') String rootDirectory: '.'}) async {
    final executor = await load(rootDirectory);
    await executor.execute(lifecycle.release());
  }

  @SubCommand(help: 'Runs the given command in all projects')
  exec(String command, @Rest() List<String> args, {@Option(
      help: 'The directory that contains the root of the projecs',
      abbr: 'd') String rootDirectory: '.'}) async {
    final executor = await load(rootDirectory);
    await executor.execute(process.process(command, args));
  }

  Future<CommandExecutor> load(String rootDirectory) async {
    final Directory installDir =
        rootDirectory == '.' ? Directory.current : new Directory(rootDirectory);
    final ProjectGroup projectGroup = await ProjectGroup.load(installDir);

    final executor = new CommandExecutor(projectGroup);
    return executor;
  }
}

/*
  jefe feature start fbar
  jefe feature finish fbar
 */