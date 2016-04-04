import 'dart:async';
import 'dart:io';

import 'package:git/git.dart';
import 'package:path/path.dart' as p;
import 'package:pubspec/pubspec.dart';
import 'package:jefe/jefe.dart';
import 'package:jefe/src/git/git.dart';

Future<Iterable<Directory>> createTestProjects(int projectCount) async {
  final testGitRemoteDir = await _setupTestDirs();

  return Future.wait(new Iterable.generate(projectCount)
      .map((i) => _copyTestProject(testGitRemoteDir, 'project${i + 1}')));
}

Future<Directory> createJefeWithTestProjects(int projectCount) async =>
    await createJefeGroup(await createTestProjectsWithRemotes(projectCount));

Future<Iterable<Directory>> createTestProjectsWithRemotes(
    int projectCount) async {
  final projects = await createTestProjects(projectCount);

  final bareRepoParentDir = await new Directory(
          p.join(projects.first.parent.parent.path, 'testBareGitRemotes'))
      .create(recursive: true);

  final bareProjects = await Future.wait(projects
      .map((p) => createBareClone(new Directory(p.path), bareRepoParentDir)));
  return bareProjects;
}

Future<Directory> createBareClone(
        Directory sourceRepo, Directory targetParent) async =>
    cloneInto(sourceRepo.path, targetParent,
        bareRepo: true, targetDirName: p.basename(sourceRepo.path));

Future<Directory> createJefeGroup(Iterable<Directory> projects) async {
  final jefeDir =
      new Directory(p.join(projects.first.parent.path, 'testGroup'));

  await jefeDir.create();

  final jefeFile = new ProjectGroupMetaData('testGroup', [], projects.map((d) {
    final projectName = p.basename(d.path);
    return new ProjectIdentifier(projectName, d.path);
  }));

  await jefeFile.save(jefeDir);

  await _gitInit(jefeDir);

  return jefeDir;
}

Future<Directory> copyTestProject(String newProjectName) async {
  final testGitRemoteDir = await _setupTestDirs();

  return await _copyTestProject(testGitRemoteDir, newProjectName);

//  final project = await Project.load(testProjectRemoteDir);
//  await project.pubspec
//      .copy(name: newProjectName)
//      .save(project.installDirectory);
//  return project;
}

Future<Directory> _setupTestDirs() async {
  final testRootDir = await Directory.systemTemp.createTemp('testRoot');

  final testGitRemoteDir =
      new Directory(p.join(testRootDir.path, 'testGitRemotes'));

  await testGitRemoteDir.create(recursive: true);
  return testGitRemoteDir;
}

Future<Directory> _copyTestProject(
    Directory testGitRemoteDir, String newProjectName) async {
  Directory testProjectTemplateDir =
      new Directory('test/integration/test_project_template');

  final testProjectRemoteDir =
      new Directory(p.join(testGitRemoteDir.path, newProjectName));

//  print(testProjectRemoteDir);

  await _copyDir(testProjectTemplateDir, testProjectRemoteDir);

  final pubSpec = await PubSpec.load(testProjectRemoteDir);
  final newPubSpec = pubSpec.copy(name: newProjectName);

  await newPubSpec.save(testProjectRemoteDir);

  await _gitInit(testProjectRemoteDir);

  return testProjectRemoteDir;
}

Future _gitInit(Directory testProjectRemoteDir) async {
  final gitDir = await GitDir.init(testProjectRemoteDir, allowContent: true);

  await gitDir.runCommand(['add', '.']);
  await gitDir.runCommand(['commit', '-am', 'blah']);
}

Future _copyDir(Directory sourceDir, Directory targetDir) async {
//  print('_copyDir($sourceDir, $targetDir)');

  await targetDir.create(recursive: true);

  return sourceDir
      .list(recursive: false)
      .asyncMap((sourceEntity) => _copy(sourceEntity, targetDir))
      .toList();
}

Future _copyFile(File sourceFile, File targetFile) async {
//  print('_copyFile($sourceFile, $targetFile)');

  return sourceFile.copy(targetFile.path);
}

Future _copy(FileSystemEntity sourceEntity, Directory targetDir) {
//  print('_copy($sourceEntity, $targetDir)');
  final newTargetPath = p.join(targetDir.path, p.basename(sourceEntity.path));

//  print('newTargetPath: $newTargetPath');

  return sourceEntity is Directory
      ? _copyDir(sourceEntity, new Directory(newTargetPath))
      : _copyFile(sourceEntity as File, new File(newTargetPath));
}
