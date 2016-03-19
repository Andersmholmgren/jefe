import 'dart:io';
import 'package:jefe/jefe.dart';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:git/git.dart';

Future<Project> copyTestProject(String newProjectName) async {
  Directory testProjectTemplateDir =
      new Directory('test/integration/test_project_template');
  print(testProjectTemplateDir.existsSync());

  final testRootDir = await Directory.systemTemp.createTemp('testRoot');

  final testProjectDir =
      new Directory(p.join(testRootDir.path, newProjectName));

  print(testProjectDir);

  await _copyDir(testProjectTemplateDir, testProjectDir);

  await GitDir.init(testProjectDir);

  final project = await Project.load(testProjectDir);
  await project.pubspec
      .copy(name: newProjectName)
      .save(project.installDirectory);
  return project;
}

Future _copyDir(Directory sourceDir, Directory parentDir) async {
  print('_copyDir($sourceDir, $parentDir)');
  final targetDir =
      new Directory(p.join(parentDir.path, p.basename(sourceDir.path)));

  await targetDir.create(recursive: true);

  return sourceDir
      .list(recursive: true)
      .asyncMap((sourceEntity) => _copy(sourceEntity, targetDir))
      .toList();
}

Future _copyFile(File sourceFile, Directory targetDir) async {
  print('_copyFile($sourceFile, $targetDir)');

  final targetFile =
      new File(p.join(targetDir.path, p.basename(sourceFile.path)));
  return sourceFile.copy(targetFile.path);
}

Future _copy(FileSystemEntity sourceEntity, Directory targetDir) =>
    sourceEntity is Directory
        ? _copyDir(sourceEntity, targetDir)
        : _copyFile(sourceEntity as File, targetDir);
