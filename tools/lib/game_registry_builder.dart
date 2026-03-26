import 'dart:convert';

import 'package:build/build.dart';
import 'package:werewolf_annotations/register_role.dart';
import 'package:werewolf_annotations/register_team.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

Builder registryCollectorBuilder(_) => RegistryCollectorBuilder();

Builder gameRegistryBuilder(_) => GameRegistryBuilder();

class RegistryCollectorBuilder implements Builder {
  @override
  final buildExtensions = const {
    '.dart': ['.registry.json'],
  };

  static final _checkerRole = TypeChecker.typeNamed(RegisterRole);
  static final _checkerTeam = TypeChecker.typeNamed(RegisterTeam);

  @override
  Future<void> build(BuildStep buildStep) async {
    final input = buildStep.inputId;

    // Skip generated files
    if (input.path.contains('.g.dart')) return;

    final library = await buildStep.resolver.libraryFor(input);
    final reader = LibraryReader(library);

    final roles = <Map<String, String>>[];
    final teams = <Map<String, String>>[];

    for (final element in reader.classes) {
      if (_checkerRole.hasAnnotationOfExact(element)) {
        roles.add({'name': element.name!, 'import': input.uri.toString()});
      }
      if (_checkerTeam.hasAnnotationOfExact(element)) {
        teams.add({'name': element.name!, 'import': input.uri.toString()});
      }
    }

    if (roles.isEmpty && teams.isEmpty) {
      // Important: write empty file for proper invalidation
      await buildStep.writeAsString(
        input.changeExtension('.registry.json'),
        jsonEncode({}),
      );
      return;
    }

    await buildStep.writeAsString(
      input.changeExtension('.registry.json'),
      jsonEncode({'roles': roles, 'teams': teams}),
    );
  }
}

class GameRegistryBuilder implements Builder {
  @override
  final buildExtensions = const {
    r'$lib$': ['game/game_registry.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final roles = <({String name, String import})>{};
    final teams = <({String name, String import})>{};

    await for (final asset in buildStep.findAssets(
      Glob('**/*.registry.json'),
    )) {
      final content = await buildStep.readAsString(asset);
      final Map<String, dynamic> data = jsonDecode(content);

      for (final item in data['roles'] ?? []) {
        roles.add((
          name: item['name'] as String,
          import: item['import'] as String,
        ));
      }

      for (final item in data['teams'] ?? []) {
        teams.add((
          name: item['name'] as String,
          import: item['import'] as String,
        ));
      }
    }

    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY')
      ..writeln('// coverage:ignore-file')
      ..writeln('// ignore_for_file: type=lint')
      ..writeln();

    // Deduplicated imports
    final imports = {...roles, ...teams};
    for (final imp in imports) {
      buffer.writeln("import '${imp.import}' show ${imp.name};");
    }

    buffer.writeln();
    buffer.writeln('class GameRegistry {');

    // Roles
    buffer.writeln('  /// Register all roles annotated with @RegisterRole.');
    buffer.writeln('  static void registerRoles() {');
    for (final role in roles) {
      buffer.writeln('    ${role.name}.registerRole();');
    }
    buffer.writeln('  }');
    buffer.writeln();

    // Teams
    buffer.writeln('  /// Register all teams annotated with @RegisterTeam.');
    buffer.writeln('  static void registerTeams() {');
    for (final team in teams) {
      buffer.writeln('    ${team.name}.registerTeam();');
    }
    buffer.writeln('  }');

    buffer.writeln('}');

    final outputId = AssetId(
      buildStep.inputId.package,
      'lib/game/game_registry.g.dart',
    );

    await buildStep.writeAsString(outputId, buffer.toString());
  }
}
