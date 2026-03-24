import 'dart:collection';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart' show BuildContext;
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/model/team.dart' show TeamType;
import 'package:werewolf_narrator/game/role/ambiguous/wild_child.dart'
    show WildChildRole;
import 'package:werewolf_narrator/game/role/ambiguous/wolf_hound.dart'
    show WolfHoundRole;
import 'package:werewolf_narrator/game/role/loner/angel.dart' show AngelRole;
import 'package:werewolf_narrator/game/role/loner/piper.dart';
import 'package:werewolf_narrator/game/role/loner/white_wolf.dart'
    show WhiteWolfRole;
import 'package:werewolf_narrator/game/role/village/bear_tamer.dart'
    show BearTamerRole;
import 'package:werewolf_narrator/game/role/village/bodyguard.dart'
    show BodyguardRole;
import 'package:werewolf_narrator/game/role/village/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/game/role/village/doctor.dart'
    show DoctorRole;
import 'package:werewolf_narrator/game/role/village/elder.dart' show ElderRole;
import 'package:werewolf_narrator/game/role/village/fox.dart' show FoxRole;
import 'package:werewolf_narrator/game/role/village/hunter.dart'
    show HunterRole;
import 'package:werewolf_narrator/game/role/village/knight_of_the_rusty_sword.dart'
    show KnightOfTheRustySwordRole;
import 'package:werewolf_narrator/game/role/village/little_girl.dart'
    show LittleGirlRole;
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/role/village/priest.dart'
    show PriestRole;
import 'package:werewolf_narrator/game/role/village/pyjama_pal.dart';
import 'package:werewolf_narrator/game/role/village/seer.dart' show SeerRole;
import 'package:werewolf_narrator/game/role/village/thief.dart' show ThiefRole;
import 'package:werewolf_narrator/game/role/village/two_sisters.dart'
    show TwoSistersRole;
import 'package:werewolf_narrator/game/role/village/villager.dart'
    show VillagerRole;
import 'package:werewolf_narrator/game/role/werewolves/ancient_werewolf.dart'
    show AncientWerewolfRole;
import 'package:werewolf_narrator/game/role/werewolves/big_bad_wolf.dart'
    show BigBadWolfRole;
import 'package:werewolf_narrator/game/role/werewolves/werewolf.dart'
    show WerewolfRole;
import 'package:werewolf_narrator/game/role/village/witch.dart' show WitchRole;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';

class RoleType<T extends Role> {
  const RoleType._();

  static final _roleMap = <Type, RoleType>{};

  factory RoleType() {
    if (!_roleMap.containsKey(T)) {
      _roleMap[T] = RoleType<T>._();
    }
    return _roleMap[T] as RoleType<T>;
  }

  /// The unique type of this role.
  Type get type => T;

  @override
  bool operator ==(Object other) => other is RoleType<T>;
  @override
  int get hashCode => T.hashCode;

  /// The registered role information for this role type.
  RegisterRoleInformation<T> get information =>
      RoleManager.getRoleInformation(this) as RegisterRoleInformation<T>;

  @override
  String toString() => 'Role<$T>';
}

abstract class RoleManager {
  static final LinkedHashMap<RoleType, RegisterRoleInformation>
  _roleInformation = LinkedHashMap();
  static bool _registered = false;

  /// Ensures that all roles are registered.
  static void ensureRegistered() {
    if (!_registered) {
      _registerRoles();
      _registered = true;
    }
  }

  static void _registerRoles() {
    // Village roles
    VillagerRole.registerRole();
    SeerRole.registerRole();
    WitchRole.registerRole();
    HunterRole.registerRole();
    CupidRole.registerRole();
    LittleGirlRole.registerRole();
    TwoSistersRole.registerRole();
    FoxRole.registerRole();
    KnightOfTheRustySwordRole.registerRole();
    ElderRole.registerRole();
    BearTamerRole.registerRole();
    ThiefRole.registerRole();
    PriestRole.registerRole();
    DoctorRole.registerRole();
    BodyguardRole.registerRole();
    PyjamaPalRole.registerRole();

    // Miscellanious roles
    WildChildRole.registerRole();
    WolfHoundRole.registerRole();

    // Werewolf roles
    WerewolfRole.registerRole();
    AncientWerewolfRole.registerRole();
    BigBadWolfRole.registerRole();

    // Solo roles
    WhiteWolfRole.registerRole();
    PiperRole.registerRole();
    AngelRole.registerRole();
  }

  /// Registers a role with the given information.
  static void registerRole<T extends Role>(
    RoleType<T> roleType,
    RegisterRoleInformation<T> info,
  ) {
    if (_roleInformation.containsKey(roleType)) {
      throw Exception('Role of type $T is already registered');
    }
    _roleInformation[roleType] = info;
  }

  /// Instantiates a new role of the given type.
  static Role instantiateRole(RoleType role, RoleConfiguration config) {
    final info = _roleInformation[role];
    if (info != null) {
      return info.constructor(config);
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
}

class RegisterRoleInformation<T extends Role> {
  /// The constructor function for this role.
  final Role Function(RoleConfiguration config) constructor;

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
  final IList<RoleOption> options;

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

class ChooseRolesCategory {
  final String Function(BuildContext context) name;
  final int priority;

  const ChooseRolesCategory._({required this.name, required this.priority});

  static const werewolves = ChooseRolesCategory._(
    name: _werewolvesName,
    priority: 20,
  );
  static String _werewolvesName(BuildContext context) =>
      AppLocalizations.of(context).roleCategory_werewolves_name;

  static const village = ChooseRolesCategory._(
    name: _villageName,
    priority: 15,
  );
  static String _villageName(BuildContext context) =>
      AppLocalizations.of(context).roleCategory_village_name;

  static const ambiguous = ChooseRolesCategory._(
    name: _ambiguousName,
    priority: 10,
  );
  static String _ambiguousName(BuildContext context) =>
      AppLocalizations.of(context).roleCategory_ambiguous_name;

  static const loner = ChooseRolesCategory._(name: _lonerName, priority: 5);
  static String _lonerName(BuildContext context) =>
      AppLocalizations.of(context).roleCategory_loner_name;
}
