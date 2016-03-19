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

  await GitDir.init(testProjectDir, allowContent: true);

  final project = await Project.load(testProjectDir);
  await project.pubspec
      .copy(name: newProjectName)
      .save(project.installDirectory);
  return project;
}

Future _copyDir(Directory sourceDir, Directory targetDir) async {
  print('_copyDir($sourceDir, $targetDir)');

  await targetDir.create(recursive: true);

  return sourceDir
      .list(recursive: false)
      .asyncMap((sourceEntity) => _copy(sourceEntity, targetDir))
      .toList();
}

Future _copyFile(File sourceFile, File targetFile) async {
  print('_copyFile($sourceFile, $targetFile)');

  return sourceFile.copy(targetFile.path);
}

Future _copy(FileSystemEntity sourceEntity, Directory targetDir) {
  print('_copy($sourceEntity, $targetDir)');
  final newTargetPath = p.join(targetDir.path, p.basename(sourceEntity.path));

  print('newTargetPath: $newTargetPath');

  return sourceEntity is Directory
      ? _copyDir(sourceEntity, new Directory(newTargetPath))
      : _copyFile(sourceEntity as File, new File(newTargetPath));
}
