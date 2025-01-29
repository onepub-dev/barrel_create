# CREATE BARREL

Create Barrel is a CLI tool that creates a barrel file for the passed
 directory(s).

 A barrel file is a dart library that exports a list of files so that
 you can import the barrel file rather than each individual file.


For example if you had a directory call `dao` with the following files:

```bash
/dao
dao_job.dart
dao_customer.dart
dao_contact.dart
```

Create Barrel would create a barrel file in that directory (called dao.g.dart):

`dao.g.dart`
```dart
//
// Generated file. Do not modify.
// Created by `barrel_create`
//
export 'dao_job.dart';
export 'dao_customer.dart';
export 'dao_contact.dart';
```

So now you can import the barrel file rather than each individual file:

```dart
import 'dao_job.dart';
import 'dao_customer.dart';
import 'dao_contact.dart';
```
becomes:

```dart
import 'dao/dao.g.dart';
```
 
To create a barrel file:

```bash
dart pub global activate barrel_create
barrel_create [-t=n] [--r] <path to directory> [path to directory]...
```

## Examples

To avoid having to retype the arguments you can create a [settings file](#settings-file) for each
project that controls where barrel_create creates barrel files.


### recursively create barrel files for every directory that contains at least 3 Dart files.

```bash
cd my/project/root
barrel_create 
```

Barrel Create also has a short cut `brl`
```bash
cd my/project/root
brl
```


### create a barrel file for a specific directory
```bash
cd my/project/root
barrel_create lib/src/dao
```

### create a barrel file for multiple directory
```bash
cd my/project/root
barrel_create lib/src/dao lib/src/entity
```

### create a barrel file for any directory in my project with at least 10 dart libraries
```bash
cd my/project/root
barrel_create -t 10 
```
### create a barrel file for all directory under lib/src/ui with at
least 4 libraries.
```bash
cd my/project/root
barrel_create -t 4 -r lib/src/ui
```

# Advanced options

## mulitple directories

You can pass a list of directories to barrel_create and it will
process each directory in turn:

```
barrel_create pigation2/pig_common/  pigation2/pig_server
```

## recursion

By passing in the --recursion (-r) flag, barrel create will recursively process
all directories under each of the passed directories.

```
barrel_create -r pigation2/pig_common/  pigation2/pig_server
```

## threshold
By default, when recursing, barrel_create will only create a barrel file for directories
which contain at least three dart libraries.

If you pass a directory, but don't specify the --recursive option, then a barrel
file will be created even if no dart files exist in the directory (i.e. threshold is ignored).

You can change the threshold by passing the --threshold (-t) flag

```
barrel_create -t 10 pigation2/pig_common/  pigation2/pig_server
```

## quite
When recursing barrel_create reports any direct that it inspected but didn't have enough .dart files to trigger the creation of a Barrel file. You can suppress this
warning by passing the `--quite (-q)` flag.

## generated directories
If barrel_create detects a directory that has generated files in it (other than its own file)
then it will not generate a barrel file in that directory.

> Most generated directories already have a barrel file created
by the generation tool.

If you want barrel_create to create a barrel file then use the touch command (or an editor) to
create an empty barrel file in that directory and from then on barrel_create
will create a barrel file in that directory.

So if you have directory:

```
generated
generate\customer.json.g.dart
```

Create an empty file:
`generate\generate.g.dart`

```
generated
generate\generate.g.dart
generate\customer.json.g.dart
```

On the next run barrel_create will overwrite `generate.g.dart` with a barrel
file.


# Settings File
To save you from having to type the same args to barrel_create each time you 
run it, you can instead create a settings file in your dart projects
tool directory.

Whenever you run barrel_create without any arguments and a settings file exist,then the settings will be used.

The settings file is placed in:
`<my project>/tool/barrel_create.yaml`

## Example

```yaml
quite: true
threshold: 10
recursive: true
directories:
  - /home/bsutton/git/pigation2/pig_common
  - /home/bsutton/git/pigation2/pig_server
```

To use the settings file:

```bash
cd myproject
barrel_create
```