import 'package:unscripted/unscripted.dart';
import 'dart:io';
import 'package:devops/devops.dart';
import 'package:logging/logging.dart';

main(arguments) => new Script(Jefe).execute(arguments);

class Jefe {
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
    final lifecycle = new ProjectLifecycle();
    await executor.executeAll(lifecycle.init());
  }
}

/*
  jefe install git@... foo
  jefe feature start fbar
  jefe feature finish fbar
 */
