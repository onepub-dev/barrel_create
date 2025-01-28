#! /home/bsutton/.dswitch/active/dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:settings_yaml/settings_yaml.dart';

const barrelSettingsFilename = 'barrel_create.yaml';

/// Creates a barrel file for the given directory.
/// The barrel file is named `<directory>`.g.dart and
/// is stored in the directory.
void main(List<String> arguments) {
  final parser = ArgParser()
    ..addFlag('recursive', abbr: 'r', negatable: false, help: '''
recursively creates barrel files for each passed directory''')
    ..addFlag('quite',
        abbr: 'q', negatable: false, help: "Don't report skipped directories")
    ..addOption('threshold',
        abbr: 't',
        defaultsTo: '3',
        help:
            '''The number of .dart files that must be in a directory, for a barrel to be created when recursing.''');

  ArgResults parsed;
  try {
    parsed = parser.parse(arguments);
  } on FormatException catch (e) {
    print(red(e.message));
    usage(parser);
    exit(1);
  }

  var recursive = parsed['recursive'] as bool;
  var quite = parsed['quite'] as bool;
  var threshold = int.tryParse(parsed['threshold'] as String);

  final directories = <String>[];

  final dartProject = DartProject.findProject('.');

  var usingSettings = false;

  /// No args so look for settings.
  if (arguments.isEmpty) {
    if (dartProject == null) {
      print(red('''
You must either pass a directory or run barrel_create from within a Dart project'''));
      usage(parser);
      exit(1);
    }
    final pathToSettings =
        join(dartProject.pathToToolDir, barrelSettingsFilename);
    if (exists(pathToSettings)) {
      usingSettings = true;
      final settings = SettingsYaml.load(pathToSettings: pathToSettings);
      quite = settings.asBool('quite', defaultValue: false);
      recursive = settings.asBool('recursive', defaultValue: false);
      threshold = settings.asInt('threshold', defaultValue: 3);

      directories.addAll(settings.asStringList('directories'));
      print(blue('Processing directories found in $pathToSettings'));
    }
  }

  if (!usingSettings && parsed.rest.isEmpty) {
    if (dartProject == null) {
      print(red("The current directory isn't within a project"));
      exit(1);
    }

    if (threshold == null) {
      print(red('The threshold must be an +ve integer'));
      usage(parser);
      exit(1);
    }

    /// If we are not recursive the user intends to create a barrel file
    /// so we remove the threshold.
    if (!recursive) {
      threshold = 0;
    }

    recursive = true;
    directories.add('.');
  } else {
    for (final directory in parsed.rest) {
      if (!exists(directory)) {
        print(red('The $directory does not exists'));
        exit(1);
      }

      if (!isDirectory(directory)) {
        print(red('$directory is not a directory'));
        exit(1);
      }
      directories.add(directory);
    }
  }

  if (directories.isEmpty) {
    print(red('No directories to be processed'));
  }
  for (final directory in directories) {
    final dartProject = DartProject.findProject(directory);
    if (dartProject == null) {
      print(red("The directory $directory isn't within a project"));
      exit(1);
    }
    print(orange('Processing $directory'));
    _createBarrel(directory,
        recursive: recursive,
        threshold: threshold!,
        quite: quite,
        reportEmpty: true,
        projectRoot: dartProject.pathToProjectRoot);
  }
}

void _createBarrel(String directory,
    {required bool recursive,
    required int threshold,
    required bool reportEmpty,
    required String projectRoot,
    required bool quite}) {
  final directoryName = basename(directory);
  final barrelFileName = '$directoryName.g.dart';
  final barrelFilePath = join(directory, barrelFileName);

  if (recursive) {
    final subdirectories = find('*',
            types: [Find.directory],
            recursive: recursive,
            workingDirectory: directory)
        .toList();
    for (final subdir in subdirectories) {
      _createBarrel(subdir,
          recursive: false,
          threshold: threshold,
          quite: quite,
          reportEmpty: false,
          projectRoot: projectRoot);
    }
  } else {
    var relativeDirName = relative(directory, from: projectRoot);
    if (relativeDirName == '.') {
      relativeDirName = directory;
    }

    // Collect all Dart files except the barrel file itself
    final dartFiles =
        find('*.dart', recursive: recursive, workingDirectory: directory)
            .toList();

    if (dartFiles.length < threshold) {
      if (!quite) {
        print('Skipping: $relativeDirName as < $threshold files');
      }
      return;
    }

    if (!dartFiles.contains(barrelFilePath) &&
        dartFiles.firstWhereOrNull((file) => file.endsWith('.g.dart')) !=
            null) {
      if (!quite) {
        print('Skipping: $relativeDirName as it contains generated files');
      }
      return;
    }

    dartFiles.sort();

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
    print(green('Created:  ${relative(barrelFilePath, from: projectRoot)}'));
  }
}

void usage(ArgParser parser) {
  print('''

${green('barrel_create creates a barrel file in each of the passed directories')}

barrel_create [-t=n] [--r] <path to directory> [path to directory]...

${parser.usage}

Create a tool/barrel_create.yaml file under your Dart Project root to save re-typing the same arguments.
''');
}
