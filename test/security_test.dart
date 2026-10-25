import 'dart:io';

import 'package:barrel_create/src/process.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory area;
  late Directory project;

  setUp(() {
    area = Directory.systemTemp.createTempSync('barrel-security-');
    project = Directory(p.join(area.path, 'project'))..createSync();
    File(p.join(project.path, 'pubspec.yaml')).writeAsStringSync('''
name: barrel_security_fixture
environment:
  sdk: '>=3.6.0 <4.0.0'
''');
  });

  tearDown(() => area.deleteSync(recursive: true));

  void generate(String directory) => processDirectories(
        directories: [directory],
        threshold: 1,
        reportEmpty: false,
        projectRoot: project.path,
        quiet: true,
        debug: false,
        progress: (_) {},
      );

  test('does not write through a lib symlink outside the project', () {
    final outside = Directory(p.join(area.path, 'outside'))..createSync();
    File(p.join(outside.path, 'pubspec.yaml'))
        .writeAsStringSync('name: outside\n');
    File(p.join(outside.path, 'source.dart'))
        .writeAsStringSync('class Source {}');
    Link(p.join(project.path, 'lib')).createSync(outside.path);

    generate(p.join(project.path, 'lib'));

    expect(File(p.join(outside.path, 'lib.g.dart')).existsSync(), isFalse);
  });

  test('does not treat a lib-prefixed sibling as the lib directory', () {
    final directory = Directory(p.join(project.path, 'library'))..createSync();
    File(p.join(directory.path, 'source.dart'))
        .writeAsStringSync('class Source {}');

    generate(directory.path);

    expect(
        File(p.join(directory.path, 'library.g.dart')).existsSync(), isFalse);
  });

  test('does not normalize symlink parent traversal before containment', () {
    if (Platform.isWindows) {
      return;
    }
    final safe = Directory(p.join(project.path, 'lib', 'widgets'))
      ..createSync(recursive: true);
    File(p.join(safe.path, 'source.dart')).writeAsStringSync('class Safe {}');

    final outside = Directory(p.join(area.path, 'outside'))..createSync();
    File(p.join(outside.path, 'pubspec.yaml'))
        .writeAsStringSync('name: outside\n');
    Directory(p.join(outside.path, 'child')).createSync();
    final target = Directory(p.join(outside.path, 'widgets'))..createSync();
    File(p.join(target.path, 'source.dart'))
        .writeAsStringSync('class Outside {}');
    Link(p.join(project.path, 'lib', 'link'))
        .createSync(p.join(outside.path, 'child'));

    generate(p.join(project.path, 'lib', 'link', '..', 'widgets'));

    expect(File(p.join(target.path, 'widgets.g.dart')).existsSync(), isFalse);
  });

  test('does not overwrite a barrel symlink', () {
    final directory = Directory(p.join(project.path, 'lib', 'widgets'))
      ..createSync(recursive: true);
    File(p.join(directory.path, 'source.dart'))
        .writeAsStringSync('class Source {}');
    final outside = File(p.join(area.path, 'outside.dart'))
      ..writeAsStringSync('preserve me');
    Link(p.join(directory.path, 'widgets.g.dart')).createSync(outside.path);

    expect(() => generate(directory.path), throwsA(isA<FileSystemException>()));
    expect(outside.readAsStringSync(), 'preserve me');
  });

  test('escapes quotes and interpolation in generated export URIs', () {
    final directory = Directory(p.join(project.path, 'lib', 'widgets'))
      ..createSync(recursive: true);
    const filename = r"bad'${injected}.dart";
    File(p.join(directory.path, filename)).writeAsStringSync('class Safe {}');

    generate(directory.path);

    final barrel =
        File(p.join(directory.path, 'widgets.g.dart')).readAsStringSync();
    expect(barrel, contains('export "bad\'%24%7Binjected%7D.dart";'));
  });

  test('escapes directive separators in generated export URIs', () {
    if (Platform.isWindows) {
      return;
    }
    final directory = Directory(p.join(project.path, 'lib', 'widgets'))
      ..createSync(recursive: true);
    File(p.join(directory.path, 'bad"; export "injected.dart'))
        .writeAsStringSync('class Safe {}');

    generate(directory.path);

    final barrel =
        File(p.join(directory.path, 'widgets.g.dart')).readAsStringSync();
    expect(barrel, contains('export "bad%22%3B%20export%20%22injected.dart";'));
    expect(barrel.split('\n').where((line) => line.startsWith('export ')),
        hasLength(1));
  });

  test('percent signs in filenames resolve to the same source file', () {
    final directory = Directory(p.join(project.path, 'lib', 'widgets'))
      ..createSync(recursive: true);
    const filename = 'a%20b.dart';
    File(p.join(directory.path, filename)).writeAsStringSync('class Safe {}');

    generate(directory.path);

    final barrel =
        File(p.join(directory.path, 'widgets.g.dart')).readAsStringSync();
    expect(barrel, contains('export "a%2520b.dart";'));
    expect(Uri.parse('a%2520b.dart').pathSegments.single, filename);
  });
}
