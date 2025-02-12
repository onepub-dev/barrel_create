import 'package:dcli/dcli.dart';
import 'package:test/test.dart';

import 'common.dart';

void main() {
  test('skip non lib directories', () async {
    await withinTestArea((testArea) {
      final pathToExe = absolutePathToExe;
      final lines = runBarrelCreate(testArea, pathToExe, '-t 3 --no-quiet');

      // final lines = <String>[];

      // processDirectories(
      //     directories: [testArea.pathToCopyOfArtifacts],
      //     quiet: false,
      //     threshold: 3,
      //     reportEmpty: false,
      //     projectRoot: pathToTestProject,
      //     progress: lines.add);

      print(lines);
      var line = 0;

      print('lines');

      expect(lines.length, equals(11));
      expect(Ansi.strip(lines[line++]), equals('Excluded:   .'));
      expect(Ansi.strip(lines[line++]), equals('Excluded:   android'));
      expect(Ansi.strip(lines[line++]), equals('Processing: lib'));
      expect(Ansi.strip(lines[line++]), equals('Skipping:   lib as < 3 files'));
      expect(Ansi.strip(lines[line++]), equals('Processing: lib/files_0'));
      expect(Ansi.strip(lines[line++]),
          equals('Skipping:   lib/files_0 as < 3 files'));
      expect(Ansi.strip(lines[line++]), equals('Processing: lib/files_2'));
      expect(Ansi.strip(lines[line++]),
          equals('Skipping:   lib/files_2 as < 3 files'));
      expect(Ansi.strip(lines[line++]), equals('Processing: lib/files_3'));
      expect(Ansi.strip(lines[line++]),
          equals('Created:    lib/files_3/files_3.g.dart'));

      expect(Ansi.strip(lines[line++]),
          equals('Finished:   created 1 barrel files.'));
    });
  });
}
