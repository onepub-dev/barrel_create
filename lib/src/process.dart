#! /home/bsutton/.dswitch/active/dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:strings/strings.dart';

var barrelsCreated = 0;

void processDirectories(
    {required List<String> directories,
    required int threshold,
    required bool reportEmpty,
    required String projectRoot,
    required bool quiet,
    required bool debug,
    required void Function(String) progress}) {
  for (final directory in directories) {
    final dartProject = DartProject.findProject(directory);
    if (dartProject == null) {
      print(red("The directory $directory isn't within a project"));
      exit(1);
    }
    if (debug) {
      print('processing $directory');
    }

    _processDirectory(
        directory: directory,
        threshold: threshold,
        quiet: quiet,
        reportEmpty: false,
        projectRoot: projectRoot,
        progress: progress);
  }
  progress(message(
      label: 'Finished',
      detail: 'created $barrelsCreated barrel files.',
      color: orange));
}

/// Creates a barrel file in [directory] and each subdirectory
/// providing they meet the threshold requirement.
void _processDirectory(
    {required String directory,
    required int threshold,
    required bool reportEmpty,
    required String projectRoot,
    required bool quiet,
    required void Function(String line) progress}) {
  /// First create barrel for the directory itself.
  _createBarrel(
      directory: directory,
      threshold: threshold,
      quiet: quiet,
      reportEmpty: false,
      projectRoot: projectRoot,
      progress: progress);

  /// now each of it's children.
  final subdirectories =
      find('*', types: [Find.directory], workingDirectory: directory).toList()
        ..sort();

  for (final subdir in subdirectories) {
    _createBarrel(
        directory: subdir,
        threshold: threshold,
        quiet: quiet,
        reportEmpty: false,
        projectRoot: projectRoot,
        progress: progress);
  }
}

String rel(String path, String projectRoot) =>
    relative(path, from: projectRoot);

void _createBarrel(
    {required String directory,
    required int threshold,
    required bool reportEmpty,
    required String projectRoot,
    required bool quiet,
    required void Function(String line) progress}) {
  final directoryName = basename(directory);
  final barrelFileName = '$directoryName.g.dart';
  final barrelFilePath = join(directory, barrelFileName);

  var relativeDirName = relative(directory, from: projectRoot);
  if (relativeDirName == '.') {
    relativeDirName = projectRoot;
  }

  if (!_isLibDir(directory, projectRoot)) {
    if (!quiet) {
      progress(message(label: 'Excluded', detail: rel(directory, projectRoot)));
    }
    return;
  }

  progress(
      message(label: 'Processing', detail: relativeDirName, color: orange));

  // Collect all Dart files except the barrel file itself
  final dartFiles =
      find('*.dart', recursive: false, workingDirectory: directory).toList()
        ..removeWhere((file) => basename(file) == barrelFileName)
        ..sort();

  if (dartFiles.length < threshold) {
    if (!quiet) {
      progress(message(
          label: 'Skipping', detail: '$relativeDirName as < $threshold files'));
    }
    return;
  }

  if (!dartFiles.contains(barrelFilePath) &&
      dartFiles.firstWhereOrNull((file) => file.endsWith('.g.dart')) != null) {
    if (!quiet) {
      progress(message(
          label: 'Skipping',
          detail: '$relativeDirName as it contains generated files'));
    }
    return;
  }

  dartFiles.sort();

  barrelsCreated++;

  // Generate export statements
  final exports = dartFiles.map((file) {
    final fileName = basename(file);
    return "export '$fileName';";
  }).join('\n');

  // Write the barrel file
  barrelFilePath.write('''
//
// Generated file. Do not modify.
// Created by `barrel_create`
// barrel_create is sponsored by OnePub the dart private repository
// https://onepub.dev
//
$exports''');
  progress(message(
      label: 'Created',
      detail: relative(barrelFilePath, from: projectRoot),
      color: green));
}

bool _isLibDir(String subdir, String projectRoot) {
  final rel = relative(subdir, from: projectRoot);

  /// We only process files under the lib directory.
  return rel.startsWith('lib');
}

void usage(ArgParser parser) {
  print('''

${green('barrel_create creates a barrel file in each of the passed directories')}

barrel_create [-t=n] [--r] <path to directory> [path to directory]...

${parser.usage}

Create a tool/barrel_create.yaml file under your Dart Project root to save re-typing the same arguments.
''');
}

String message(
    {required String label,
    required String detail,
    String Function(String)? color}) {
  label = '$label:';
  if (color != null) {
    return color('${Strings.padRight(label, 11)} $detail');
  } else {
    return '${Strings.padRight(label, 11)} $detail';
  }
}
