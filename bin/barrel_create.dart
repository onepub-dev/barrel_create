#! /home/bsutton/.dswitch/active/dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:barrel_create/src/process.dart';
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
    ..addFlag('quiet',
        abbr: 'q', defaultsTo: true, help: "Don't report skipped directories")
    ..addFlag('debug', abbr: 'd', hide: true, help: 'Outputs debug messages')
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

  final directories = <String>[];
  var recursive = parsed['recursive'] as bool;
  var quiet = parsed['quiet'] as bool;
  final debug = parsed['debug'] as bool;
  var threshold = int.tryParse(parsed['threshold'] as String);

  final dartProject = _pathToProject(parser);

  var usingSettings = false;

  final pathToSettings =
      join(dartProject.pathToToolDir, barrelSettingsFilename);

  /// No args so look for settings.
  if (arguments.isEmpty) {
    if (exists(pathToSettings)) {
      usingSettings = true;
      final settings = SettingsYaml.load(pathToSettings: pathToSettings);

      quiet = settings.asBool('quiet', defaultValue: quiet);
      recursive = settings.asBool('recursive', defaultValue: recursive);
      threshold ??= settings.asInt('threshold', defaultValue: threshold ?? 3);

      directories.addAll(settings.asStringList('directories'));
      print(blue('Processing directories found in $pathToSettings'));
    }
  }

  if (!usingSettings && parsed.rest.isEmpty) {
    if (threshold == null) {
      print(red('The threshold must be an +ve integer'));
      usage(parser);
      exit(1);
    }

    /// If we are not recursive the user intends to create a barrel file
    /// so we set the threshold to 2.
    if (!recursive && parsed.rest.isNotEmpty) {
      threshold = 2;
    }

    recursive = true;
    directories.add('.');
  } else {
    for (final directory in parsed.rest) {
      if (!exists(directory)) {
        print(red('The directory ${truepath(directory)} does not exists'));
        exit(1);
      }

      if (!isDirectory(directory)) {
        print(red('$directory is not a directory'));
        exit(1);
      }
      directories.add(directory);
    }
  }

  if (debug) {
    print('''
recursive: $recursive
quiet: $quiet
debug: $debug
threshold: $threshold
directories: $directories
projectRoot: ${dartProject.pathToProjectRoot}
usingSettings: $usingSettings
pathToSettings: $pathToSettings
settings file exists: ${exists(pathToSettings)}
''');
  }

  if (directories.isEmpty) {
    print(red('No directories to be processed'));
  }
  processDirectories(
      directories: directories,
      threshold: threshold!,
      quiet: quiet,
      debug: debug,
      reportEmpty: false,
      projectRoot: dartProject.pathToProjectRoot,
      progress: print);
}

DartProject _pathToProject(ArgParser parser) {
  final dartProject = DartProject.findProject('.');
  if (dartProject == null) {
    print(red('''
  You must either pass a directory or run barrel_create from within a Dart project'''));
    usage(parser);
    exit(1);
  }
  return dartProject;
}
