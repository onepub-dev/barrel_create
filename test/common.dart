import 'package:dcli/dcli.dart';
import 'package:path/path.dart' hide equals;

final pathToTestArtifacts = join('test', 'artifacts');
// final pathToTestProject = join(pathToTestArtifacts, 'test_project');
// final pathToTestProjectLib = join(pathToTestProject, 'lib');
final pathToFiles3 = join('lib', 'files_3');
final pathToFiles2 = join('lib', 'files_2');
final pathToFiles0 = join('lib', 'files_0');

List<String> runBarrelCreate(TestArea testArea, String pathToExe, String args) {
  final lines = '$pathToExe $args'
      .toList(workingDirectory: testArea.pathToProject, nothrow: true);
  return lines;
}

String get absolutePathToExe =>
    join(DartProject.self.pathToBinDir, 'barrel_create.dart');

/// Copies the test artifacts to a temp directory so that each
/// unit test runs without interference from other unit
/// tests.
Future<void> withinTestArea(void Function(TestArea testArea) action) async {
  await withTempDirAsync((tempDir) async {
    copyTree(pathToTestArtifacts, tempDir);
    action(TestArea(tempDir));
  });
}

class TestArea {
  String pathToCopyOfArtifacts;

  TestArea(this.pathToCopyOfArtifacts);

  String get pathToProject => join(pathToCopyOfArtifacts, 'test_project');

  String pathToSubDir(String testProject) =>
      join(pathToCopyOfArtifacts, testProject);
}
