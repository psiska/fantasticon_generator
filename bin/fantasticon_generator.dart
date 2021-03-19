import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:fantasticon_generator/generate_flutter_class.dart';
import 'package:fantasticon_generator/templates/npm_package.dart';
import 'package:fantasticon_generator/utils.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  final runner = CommandRunner('icon_font_generator', 'Generate you own fonts')
    ..addCommand(GenerateCommand());
  try {
    await runner.run(['gen', ...args]);
  } on UsageException catch (error) {
    print(error);
    exit(1);
  }
}

class GenerateCommand extends Command {
  GenerateCommand() {
    argParser
      ..addOption(
        'from',
        abbr: 'f',
        help: 'Input dir with svg\'s',
      )
      ..addOption(
        'out-font',
        help: 'Output icon font',
      )
      ..addOption(
        'out-flutter',
        help: 'Output flutter icon class',
      )
      ..addOption(
        'class-name',
        help: 'Flutter class name \ family for generating file',
      )
      ..addOption(
        'height',
        help: 'Fixed font height value',
        defaultsTo: '512',
      )
      ..addOption(
        'ascent',
        help: 'Offset applied to the baseline',
        defaultsTo: '240',
      )
      ..addOption(
        'package',
        help: 'Name of package for generated icon data (if another package)',
      )
      ..addOption(
        'indent',
        help: 'Indent for generating dart file, for example: ' ' ',
        defaultsTo: '  ',
      )
      ..addFlag(
        'mono',
        help: 'Make font monospace',
        defaultsTo: true,
      )
      ..addFlag(
        'normalize',
        help: 'Normalize icons sizes',
        defaultsTo: false,
      );
  }

  @override
  String get name => 'gen';

  @override
  String get description => 'Generate you own fonts';

  @override
  Future<void> run() async {
    print("Node check: start");
    final nodeCheckResult =
        await Process.run('node', ['--version'], runInShell: true);
    if (nodeCheckResult.exitCode != 0) {
      print('Please install Node.JS. Recommended v10+');
    }
    print("Node check: done");

    if (argResults['from'] == null ||
        argResults['out-font'] == null ||
        argResults['out-flutter'] == null ||
        argResults['class-name'] == null) {
      print('--from, --out-font, --out-flutter, '
          '--class-name args required!');
      exit(1);
    }

    final genRootDir = Directory.fromUri(Platform.script.resolve('..'));
    print("debug: genRootDir $genRootDir");

    final npmPackage = File(path.join(genRootDir.path, 'package.json'));
    print("debug: npmPackage: $npmPackage");
    if (!npmPackage.existsSync()) {
      print("debug: npm package does not exists. writing");
      await npmPackage.writeAsString(npmPackageTemplate);
    }

    final tempSourceDirectory =
        Directory.fromUri(genRootDir.uri.resolve('temp_icons'));
    final tempOutDirectory =
        Directory.fromUri(genRootDir.uri.resolve('temp_font'));
    final iconsMap = File.fromUri(genRootDir.uri.resolve('map.json'));
    if (tempSourceDirectory.existsSync()) {
      print("debug: clean temp source dir: $tempSourceDirectory");
      await tempSourceDirectory.delete(recursive: true);
    }
    if (tempOutDirectory.existsSync()) {
      print("debug: clean temp out dir: $tempOutDirectory");
      await tempOutDirectory.delete(recursive: true);
    }
    if (iconsMap.existsSync()) {
      await iconsMap.delete();
    }

    print("debug: execute 'npm install'");
    final nodeInstallDependencies = await Process.start(
      'npm',
      ['install'],
      workingDirectory: genRootDir.path,
      runInShell: true,
    );
    await stdout.addStream(nodeInstallDependencies.stdout);
    print("debug: execute npm - done");

    // icon-font-generator reguires package: `ttf2woff2`
    // we do not need him and requires a python
    final String gypErr = 'gyp ERR!';
    await stderr.addStream(nodeInstallDependencies.stderr
        .where((bytes) => !utf8.decode(bytes).contains(gypErr)));

    final sourceIconsDirectory = Directory.fromUri(Directory.current.uri
        .resolve(argResults['from'].replaceAll('\\', '/')));
    final outIconsFile = File.fromUri(Directory.current.uri
        .resolve(argResults['out-font'].replaceAll('\\', '/')));
    final outFlutterClassFile = File.fromUri(Directory.current.uri
        .resolve(argResults['out-flutter'].replaceAll('\\', '/')));

    print("debug: source icon dir  : $sourceIconsDirectory");
    print("debug: out icons file   : $outIconsFile");
    print("debug: out flutter file : $outFlutterClassFile");

    await tempSourceDirectory.create();
    await tempOutDirectory.create();

    await copyDirectory(
      sourceIconsDirectory,
      tempSourceDirectory,
    );

    // gen font
    String iconGenCmd = path.join(
        genRootDir.path,
        'node_modules/.bin/fantasticon${Platform.isWindows ? '.cmd' : ''}',
      );

    List<String> iconGenCmdParams2 = [
      '--normalize',
      '--font-types',
      'ttf',
      '--asset-types',
      'json',
      '--font-height',
      argResults['height'],
      '--output',
      path.absolute(tempOutDirectory.path),
      path.absolute(tempSourceDirectory.path)
    ];
      //path.absolute(path.join(tempSourceDirectory.path, '*.svg'))

    List<String> iconGenCmdParams = [
        path.absolute(path.join(tempSourceDirectory.path, '*.svg')),
        '--codepoint',
        '0xe000',
        '--css',
        'false',
        '--html',
        'false',
        '--height',
        argResults['height'],
        '--ascent',
        argResults['ascent'],
        '--mono',
        argResults['mono'].toString(),
        '--normalize',
        argResults['normalize'].toString(),
        '--name',
        path.basenameWithoutExtension(argResults['out-font']),
        '--out',
        path.absolute(tempOutDirectory.path),
        '--jsonpath',
        'map.json',
        '--types',
        'ttf',
      ];
    print("debug: iconGenCmd              : $iconGenCmd");
    print("debug: iconGenCmdParams        : $iconGenCmdParams");
    print("debug: iconGenCmdParamsJoined  : ${iconGenCmdParams.join(" ")}");
    print("debug: iconGenCmdParams2       : $iconGenCmdParams2");
    print("debug: iconGenCmdParams2Joined : ${iconGenCmdParams2.join(" ")}");

    final generateFont = await Process.start(iconGenCmd, iconGenCmdParams2,
      workingDirectory: genRootDir.path,
      runInShell: true,
    );

    await stdout.addStream(generateFont.stdout.map((bytes) {
      var message = utf8.decode(bytes);
      if (message == '\x1b[32mDone\x1b[39m\n') {
        message = '\x1b[32mSuccess generated font\x1b[39m\n';
      }
      return utf8.encode(message);
    }));
    final String stdlib = 'Invalid member of stdlib';
    await stderr.addStream(generateFont.stderr
        .where((bytes) => !utf8.decode(bytes).contains(stdlib)));

    await File(path.join(
      tempOutDirectory.path,
      "icons.ttf"
    )).copy(outIconsFile.path);
    await File(path.join(
      tempOutDirectory.path,
      "icons.json"
    )).copy(iconsMap.path);

      //path.basename(argResults['out-font']),
    if (!outIconsFile.existsSync()) {
      await outIconsFile.create(recursive: true);
    }

    final generateClassResult = await generateFlutterClass(
      iconMap: iconsMap,
      className: argResults['class-name'],
      packageName: argResults['package'],
      indent: argResults['indent'],
    );

    await outFlutterClassFile.writeAsString(generateClassResult.content);
    print('Successful generated '
        '\x1b[33m${path.basename(outFlutterClassFile.path)}\x1b[0m '
        'with \x1b[32m${generateClassResult.iconsCount}\x1b[0m icons'
        '\x1b[32m saved!\x1b[0m');

    await tempSourceDirectory.delete(recursive: true);
    await tempOutDirectory.delete(recursive: true);
    await iconsMap.delete();
  }
}
