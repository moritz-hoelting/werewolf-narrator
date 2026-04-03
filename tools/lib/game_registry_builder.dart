import 'dart:convert';

import 'package:build/build.dart';
import 'package:werewolf_annotations/register_role.dart';
import 'package:werewolf_annotations/register_team.dart';
import 'package:dart_mappable/dart_mappable.dart' show MappableClass;
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
  static final _checkerMappableClass = TypeChecker.typeNamed(MappableClass);

  @override
  Future<void> build(BuildStep buildStep) async {
    final input = buildStep.inputId;

    // Skip generated files
    if (input.path.contains('.g.dart')) return;

    final library = await buildStep.resolver.libraryFor(input);
    final reader = LibraryReader(library);

    final roles = <Map<String, String>>[];
    final teams = <Map<String, String>>[];
    final mappableClasses = <Map<String, String>>[];

    for (final element in reader.classes) {
      if (_checkerRole.hasAnnotationOfExact(element)) {
        roles.add({'name': element.name!, 'import': input.uri.toString()});
      }
      if (_checkerTeam.hasAnnotationOfExact(element)) {
        teams.add({'name': element.name!, 'import': input.uri.toString()});
      }
      if (_checkerMappableClass.hasAnnotationOfExact(element)) {
        mappableClasses.add({
          'name': '${element.name!}Mapper',
          'import': input.uri.toString(),
        });
      }
    }

    if (roles.isEmpty && teams.isEmpty && mappableClasses.isEmpty) {
      // Important: write empty file for proper invalidation
      await buildStep.writeAsString(
        input.changeExtension('.registry.json'),
        jsonEncode({}),
      );
      return;
    }

    await buildStep.writeAsString(
      input.changeExtension('.registry.json'),
      jsonEncode({
        'roles': roles,
        'teams': teams,
        'mappableClasses': mappableClasses,
      }),
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
    final mappableClasses = <({String name, String import})>{};

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

      for (final item in data['mappableClasses'] ?? []) {
        mappableClasses.add((
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

    buffer.writeln(
      "import 'package:werewolf_narrator/game/role/role.dart' show Role;",
    );
    buffer.writeln(
      "import 'package:werewolf_narrator/game/team/team.dart' show Team;",
    );
    buffer.writeln();

    // Deduplicated imports
    final imports = {...roles, ...teams, ...mappableClasses};
    for (final imp in imports) {
      buffer.writeln("import '${imp.import}' show ${imp.name};");
    }

    buffer.writeln();
    buffer.writeln('class GameRegistry {');
    buffer.writeln('  static bool _initialized = false;');
    buffer.writeln();

    // Ensure registered
    buffer.writeln(
      '  /// Ensures that all mappable classes, roles, and teams are registered. Should be called as early as possible.',
    );
    buffer.writeln('  static void ensureInitialized() {');
    buffer.writeln('    if (_initialized) return;');
    buffer.writeln('    _initialized = true;');
    buffer.writeln();
    buffer.writeln('    _registerMappableClasses();');
    buffer.writeln('    _registerRoles();');
    buffer.writeln('    _registerTeams();');
    buffer.writeln('  }');
    buffer.writeln();

    // Mappable classes
    buffer.writeln(
      '  /// Register all mappable classes annotated with @MappableClass.',
    );
    buffer.writeln('  static void _registerMappableClasses() {');
    for (final mappableClass in mappableClasses) {
      buffer.writeln('    ${mappableClass.name}.ensureInitialized();');
    }
    buffer.writeln('  }');
    buffer.writeln();

    // Roles
    // Role id map
    buffer.writeln('  static final Map<Type, String> _roleTypeToId = {');
    for (final role in roles) {
      buffer.writeln('    ${role.name}: "${role.name}",');
    }
    buffer.writeln('  };');
    buffer.writeln();

    // Role id methods
    buffer.writeln('  /// Gets the unique id for the given role type.');
    buffer.writeln('  static String idForRoleType<T extends Role>() {');
    buffer.writeln('    final id = _roleTypeToId[T];');
    buffer.writeln('    if (id == null) {');
    buffer.writeln(
      '      throw Exception("No id registered for role type \$T");',
    );
    buffer.writeln('    }');
    buffer.writeln('    return id;');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  /// Gets the actual role type for the given id.');
    buffer.writeln(
      "  static Type roleTypeForId(String id) => _roleTypeToId.entries",
    );
    buffer.writeln("      .firstWhere(");
    buffer.writeln("        (entry) => entry.value == id,");
    buffer.writeln(
      '        orElse: () => throw Exception("No role type registered for id \$id"),',
    );
    buffer.writeln("      )");
    buffer.writeln("      .key;");
    buffer.writeln();

    // Role registration
    buffer.writeln('  /// Register all roles annotated with @RegisterRole.');
    buffer.writeln('  static void _registerRoles() {');
    for (final role in roles) {
      buffer.writeln('    ${role.name}.registerRole();');
    }
    buffer.writeln('  }');
    buffer.writeln();

    // Teams
    // Team id map
    buffer.writeln('  static final Map<Type, String> _teamTypeToId = {');
    for (final team in teams) {
      buffer.writeln('    ${team.name}: "${team.name}",');
    }
    buffer.writeln('  };');
    buffer.writeln();

    // Team id methods
    buffer.writeln('  /// Gets the unique id for the given team type.');
    buffer.writeln('  static String idForTeamType<T extends Team>() {');
    buffer.writeln('    final id = _teamTypeToId[T];');
    buffer.writeln('    if (id == null) {');
    buffer.writeln(
      '      throw Exception("No id registered for team type \$T");',
    );
    buffer.writeln('    }');
    buffer.writeln('    return id;');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  /// Gets the actual team type for the given id.');
    buffer.writeln(
      "  static Type teamTypeForId(String id) => _teamTypeToId.entries",
    );
    buffer.writeln("      .firstWhere(");
    buffer.writeln("        (entry) => entry.value == id,");
    buffer.writeln(
      '        orElse: () => throw Exception("No team type registered for id \$id"),',
    );
    buffer.writeln("      )");
    buffer.writeln("      .key;");
    buffer.writeln();

    // Team registration
    buffer.writeln('  /// Register all teams annotated with @RegisterTeam.');
    buffer.writeln('  static void _registerTeams() {');
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
