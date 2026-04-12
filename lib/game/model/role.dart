import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart' show BuildContext;
import 'package:fpdart/fpdart.dart';
import 'package:werewolf_narrator/game/game_registry.g.dart' show GameRegistry;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/configuration_options.dart';
import 'package:werewolf_narrator/game/model/team.dart' show TeamType;
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';

part 'role.mapper.dart';

@MappableClass()
class RoleType with RoleTypeMappable {
  const RoleType._(this.id);

  @MappableConstructor()
  factory RoleType.fromId(String id) {
    GameRegistry.roleTypeForId(id); // Ensure that the role type is registered
    return RoleType._(id);
  }

  final String id;

  static final _roleMap = <String, RoleType>{};

  static RoleType of<T extends Role>() {
    final String id = GameRegistry.idForRoleType<T>();
    if (!_roleMap.containsKey(id)) {
      _roleMap[id] = RoleType._(id);
    }
    return _roleMap[id]!;
  }

  /// The unique type of this role.
  Type get type => GameRegistry.roleTypeForId(id);

  @override
  bool operator ==(Object other) => other is RoleType ? other.id == id : false;
  @override
  int get hashCode => type.hashCode;

  /// The registered role information for this role type.
  RegisterRoleInformation get information =>
      RoleManager.getRoleInformation(this) as RegisterRoleInformation;

  @override
  String toString() => 'Role<$id>';
}

abstract class RoleManager {
  static final LinkedHashMap<RoleType, RegisterRoleInformation>
  _roleInformation = LinkedHashMap();

  /// Registers a role with the given information.
  static void registerRole<T extends Role>(
    RoleType roleType,
    RegisterRoleInformation<T> info,
  ) {
    assert(
      roleType == RoleType.of<T>(),
      'The role type must match the role information',
    );
    if (_roleInformation.containsKey(roleType)) {
      throw Exception('Role of type $T is already registered');
    }
    _roleInformation[roleType] = info;
  }

  /// Instantiates a new role of the given type.
  static Role instantiateRole(
    int playerIndex,
    RoleType role,
    RoleConfiguration config,
  ) {
    final info = _roleInformation[role];
    if (info != null) {
      return info.constructor(playerIndex: playerIndex, config: config);
    } else {
      throw Exception('No constructor registered for role type $role');
    }
  }

  /// Gets the information registered for the given role type.
  static RegisterRoleInformation? getRoleInformation(RoleType role) {
    final info = _roleInformation[role];
    if (info == null) {
      throw Exception('No information registered for role type $role');
    }
    return info;
  }

  /// The list of all registered role types.
  static IList<RoleType> get registeredRoles => _roleInformation.keys.toIList();

  /// Gets the initializer function for the given role type.
  static void Function(GameState gameState)? getInitializer(RoleType role) {
    final info = _roleInformation[role];
    return info?.initialize;
  }

  static IList<({ChooseRolesCategory category, IList<RoleType> roles})>
  get categorizedRoles =>
      groupBy(
            registeredRoles,
            (role) => role.information.chooseRolesInformation.category,
          )
          .mapValue(
            (list) => list
              ..sortByCompare(
                (role) => role.information.chooseRolesInformation.priority,
                (a, b) => b.compareTo(a),
              ),
          )
          .entries
          .sortedByCompare(
            (entry) => entry.key.priority,
            (a, b) => b.compareTo(a),
          )
          .map((entry) => (category: entry.key, roles: entry.value.lock))
          .toIList();
}

class RegisterRoleInformation<T extends Role> {
  /// The constructor function for this role.
  final Role Function({
    required int playerIndex,
    required RoleConfiguration config,
  })
  constructor;

  /// The name of this role.
  final String Function(BuildContext context) name;

  /// The description of this role.
  final String Function(BuildContext context) description;

  /// The initial team for this role.
  final TeamType? initialTeam;

  /// Valid counts for this role. Must be a sorted iterable of positive integers.
  ///
  /// 0 is assumed implicitly, so it should not be included in this list.
  /// Should be sorted in ascending order.
  final Iterable<int> validRoleCounts;

  /// List of configuration options for this role.
  ///
  /// This is used to display the options in the UI and to pass the selected options to the role constructor.
  final IList<ConfigurationOption> options;

  /// The initializer function for this role.
  final void Function(GameState gameState)? initialize;

  /// The instruction for checking this role, given the current count of this role in the game.
  final String Function(BuildContext context, int count) checkRoleInstruction;

  /// The amount of additional role cards this role adds to the game.
  final int addedRoleCardAmount;

  /// The role count adjuster function for this role.
  final void Function(
    Map<RoleType, ({int count, RoleConfiguration config})> roleCounts,
    int playerCount,
  )?
  roleCountAdjuster;

  /// Information for display on choose roles screen.
  final ChooseRolesInformation chooseRolesInformation;

  /// Whether this role requires the game to start with a day phase.
  final bool requireStartGameWithDay;

  const RegisterRoleInformation({
    required this.constructor,
    required this.name,
    required this.description,
    required this.initialTeam,
    required this.checkRoleInstruction,
    required this.validRoleCounts,
    required this.chooseRolesInformation,
    this.options = const IList.empty(),
    this.initialize,
    this.addedRoleCardAmount = 1,
    this.roleCountAdjuster,
    this.requireStartGameWithDay = false,
  });
}

class ChooseRolesInformation {
  final ChooseRolesCategory category;
  final int priority;

  const ChooseRolesInformation({required this.category, this.priority = 0});
}

enum ChooseRolesCategory {
  werewolves(name: _werewolvesName, priority: 20),
  village(name: _villageName, priority: 15),
  ambiguous(name: _ambiguousName, priority: 10),
  loner(name: _lonerName, priority: 5);

  const ChooseRolesCategory({required this.name, required this.priority});

  final String Function(BuildContext context) name;
  final int priority;

  static String _werewolvesName(BuildContext context) =>
      AppLocalizations.of(context).roleCategory_werewolves_name;
  static String _villageName(BuildContext context) =>
      AppLocalizations.of(context).roleCategory_village_name;
  static String _ambiguousName(BuildContext context) =>
      AppLocalizations.of(context).roleCategory_ambiguous_name;
  static String _lonerName(BuildContext context) =>
      AppLocalizations.of(context).roleCategory_loner_name;
}
