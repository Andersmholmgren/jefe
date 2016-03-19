import 'dart:io';
import 'package:jefe/jefe.dart';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:git/git.dart';
import 'package:pubspec/pubspec.dart';

Future<Directory> copyTestProject(String newProjectName) async {
  Directory testProjectTemplateDir =
      new Directory('test/integration/test_project_template');
  print(testProjectTemplateDir.existsSync());

  final testRootDir = await Directory.systemTemp.createTemp('testRoot');

  final testGitRemoteDir =
      new Directory(p.join(testRootDir.path, 'testGitRemotes'));

  await testGitRemoteDir.create(recursive: true);

  final testProjectRemoteDir =
      new Directory(p.join(testGitRemoteDir.path, newProjectName));

  print(testProjectRemoteDir);

  await _copyDir(testProjectTemplateDir, testProjectRemoteDir);

  final gitDir = await GitDir.init(testProjectRemoteDir, allowContent: true);

  await gitDir.runCommand(['add', '.']);
  await gitDir.runCommand(['commit', '-am', 'blah']);

  final pubSpec = await PubSpec.load(testProjectRemoteDir);
  final newPubSpec = pubSpec.copy(name: newProjectName);

  await newPubSpec.save(testProjectRemoteDir);

  return testProjectRemoteDir;

//  final project = await Project.load(testProjectRemoteDir);
//  await project.pubspec
//      .copy(name: newProjectName)
//      .save(project.installDirectory);
//  return project;
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
