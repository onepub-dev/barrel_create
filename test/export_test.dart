import 'dart:io';

import 'package:barrel_create/src/process.dart';
import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'common.dart';

void main() async {
  test('barrel file does not export itself on regeneration', () async {
    await withinTestArea((testArea) {
      // Create a directory under the lib folder.
      final dir = testArea.pathToSubDir('lib/my_lib');
      createDir(dir, recursive: true);

      // Create some dart files inside the directory.
      File(join(dir, 'file1.dart')).writeAsStringSync('class File1 {}');
      File(join(dir, 'file2.dart')).writeAsStringSync('class File2 {}');
      File(join(dir, 'file3.dart')).writeAsStringSync('class File3 {}');

      // Set a low threshold so that a barrel file is created even if
      //only one file is present.
      const threshold = 1;

      // Run processDirectories to create the barrel file.
      final linesFirstRun = <String>[];
      processDirectories(
          directories: [dir],
          quiet: false,
          debug: false,
          threshold: threshold,
          reportEmpty: false,
          projectRoot: testArea.pathToProject,
          progress: linesFirstRun.add);

      // The barrel file is named after the directory basename with .g.dart
      // appended.
      final barrelFileName = '${basename(dir)}.g.dart';
      final barrelFilePath = join(dir, barrelFileName);
      final barrelFile = File(barrelFilePath);

      expect(barrelFile.existsSync(), isTrue,
          reason: 'The barrel file should be created after processing.');

      // Read the barrel file content from the first run.
      final contentFirstRun = barrelFile.readAsStringSync();

      // It should export the dart files, but NOT export itself.
      expect(contentFirstRun, contains("export 'file1.dart';"));
      expect(contentFirstRun, contains("export 'file2.dart';"));
      expect(contentFirstRun, contains("export 'file3.dart';"));
      expect(contentFirstRun, isNot(contains("export '$barrelFileName';")),
          reason: 'The barrel file should not export itself on the first run.');

      // Run processDirectories a second time (simulate re-generation).
      final linesSecondRun = <String>[];
      processDirectories(
          directories: [dir],
          quiet: false,
          debug: false,
          threshold: threshold,
          reportEmpty: false,
          projectRoot: testArea.pathToProject,
          progress: linesSecondRun.add);

      // Read the barrel file content after regeneration.
      final contentSecondRun = barrelFile.readAsStringSync();

      // Ensure that the barrel file still does not export itself.
      expect(contentSecondRun, isNot(contains("export '$barrelFileName';")),
          reason: '''
The barrel file should not include an export statement for itself after regeneration.''');
    });
  });
}
