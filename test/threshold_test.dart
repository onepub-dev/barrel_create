import 'dart:io';

import 'package:barrel_create/src/process.dart';
import 'package:dcli/dcli.dart';
import 'package:path/path.dart' hide equals;
import 'package:test/test.dart';

import 'common.dart';

void main() {
  test('threshold 3 - three files', () async {
    await withinTestArea((testArea) {
      // final pathToExe = absolutePathToExe;
      // final lines =
      //     runBarrelCreate(pathToExe, '-t 3 --no-quiet -d $pathToFiles3');

      final lines = <String>[];
      processDirectories(
          directories: [testArea.pathToSubDir(pathToFiles3)],
          quiet: false,
          debug: false,
          threshold: 3,
          reportEmpty: false,
          projectRoot: testArea.pathToProject,
          progress: lines.add);

      print(lines);

      expect(lines.length, equals(3));
      expect(Ansi.strip(lines[0]), equals('Processing: lib/files_3'));
      expect(Ansi.strip(lines[1]),
          equals('Created:    lib/files_3/files_3.g.dart'));
      expect(
          Ansi.strip(lines[2]), equals('Finished:   created 1 barrel files.'));

      final generatedLines =
          File(join(testArea.pathToSubDir(pathToFiles3), 'files_3.g.dart'))
              .readAsStringSync();

      expect(generatedLines, equals('''
//
// Generated file. Do not modify.
// Created by `barrel_create`
// barrel_create is sponsored by OnePub the dart private repository
// https://onepub.dev
//
export 'file_1.dart';
export 'file_2.dart';
export 'file_3.dart';
'''));
    });
  });

  test('threshold 3 - two files', () async {
    await withinTestArea((testArea) {
      // final pathToExe = absolutePathToExe;
      // final lines = runBarrelCreate(pathToExe, '-t 3 $pathToFiles2');

      final lines = <String>[];
      processDirectories(
          directories: [testArea.pathToSubDir(pathToFiles2)],
          quiet: true,
          debug: false,
          threshold: 3,
          reportEmpty: false,
          projectRoot: testArea.pathToProject,
          progress: lines.add);

      print(lines);
      expect(lines.length, equals(2));
      expect(Ansi.strip(lines[0]), equals('Processing: lib/files_2'));
      expect(
          Ansi.strip(lines[1]), equals('Finished:   created 0 barrel files.'));
    });
  });

  test('threshold 3- zero files', () async {
    await withinTestArea((testArea) {
      // final pathToExe = absolutePathToExe;

      // final lines = runBarrelCreate(pathToExe, '-t 3 $pathToFiles0');

      final lines = <String>[];

      processDirectories(
          directories: [testArea.pathToSubDir(pathToFiles0)],
          quiet: true,
          debug: false,
          threshold: 3,
          reportEmpty: false,
          projectRoot: testArea.pathToProject,
          progress: lines.add);
      print(lines);
      expect(lines.length, equals(2));
      expect(Ansi.strip(lines[0]), equals('Processing: lib/files_0'));
      expect(
          Ansi.strip(lines[1]), equals('Finished:   created 0 barrel files.'));
    });
  });
}
