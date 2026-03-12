import 'dart:collection';

import 'package:flutter/material.dart' show BuildContext;
import 'package:werewolf_narrator/game/model/team.dart' show TeamType;
import 'package:werewolf_narrator/game/role/misc/wild_child.dart'
    show WildChildRole;
import 'package:werewolf_narrator/game/role/misc/wolf_hound.dart'
    show WolfHoundRole;
import 'package:werewolf_narrator/game/role/village/bear_tamer.dart'
    show BearTamerRole;
import 'package:werewolf_narrator/game/role/village/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/game/role/village/elder.dart' show ElderRole;
import 'package:werewolf_narrator/game/role/village/fox.dart' show FoxRole;
import 'package:werewolf_narrator/game/role/village/hunter.dart'
    show HunterRole;
import 'package:werewolf_narrator/game/role/village/knight_of_the_rusty_sword.dart'
    show KnightOfTheRustySwordRole;
import 'package:werewolf_narrator/game/role/village/little_girl.dart'
    show LittleGirlRole;
import 'package:werewolf_narrator/game/role/role.dart';
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

    // Miscellanious roles
    WildChildRole.registerRole();
    WolfHoundRole.registerRole();

    // Werewolf roles
    WerewolfRole.registerRole();
    AncientWerewolfRole.registerRole();
    BigBadWolfRole.registerRole();
  }

  /// Registers a role with the given information.
  static void registerRole<T extends Role>(RegisterRoleInformation<T> info) {
    if (_roleInformation.containsKey(RoleType<T>())) {
      throw Exception('Role of type $T is already registered');
    }
    _roleInformation[RoleType<T>()] = info;
  }

  /// Instantiates a new role of the given type.
  static Role instantiateRole(RoleType role) {
    final info = _roleInformation[role];
    if (info != null) {
      return info.constructor();
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
  static List<RoleType> get registeredRoles =>
      List.unmodifiable(_roleInformation.keys.toList());

  /// Gets the initializer function for the given role type.
  static void Function(GameState gameState)? getInitializer(RoleType role) {
    final info = _roleInformation[role];
    return info?.initialize;
  }

  /// Gets the role count adjuster function for the given role type.
  static void Function(Map<RoleType, int> roleCounts, int playerCount)?
  getRoleCountAdjuster(RoleType role) {
    final info = _roleInformation[role];
    return info?.roleCountAdjuster;
  }
}

class RegisterRoleInformation<T extends Role> {
  /// The constructor function for this role.
  final Role Function() constructor;

  /// The name of this role.
  final String Function(BuildContext context) name;

  /// The description of this role.
  final String Function(BuildContext context) description;

  /// The initial team for this role.
  final TeamType initialTeam;

  /// Valid counts for this role. Must be a sorted iterable of positive integers.
  ///
  /// 0 is assumed implicitly, so it should not be included in this list.
  /// Should be sorted in ascending order.
  final Iterable<int> validRoleCounts;

  /// The initializer function for this role.
  final void Function(GameState gameState)? initialize;

  /// The instruction for checking this role, given the current count of this role in the game.
  final String Function(BuildContext context, int count) checkRoleInstruction;

  /// The amount of additional role cards this role adds to the game.
  final int addedRoleCardAmount;

  /// The role count adjuster function for this role.
  final void Function(Map<RoleType, int> roleCounts, int playerCount)?
  roleCountAdjuster;

  RegisterRoleInformation({
    required this.constructor,
    required this.name,
    required this.description,
    required this.initialTeam,
    required this.checkRoleInstruction,
    required this.validRoleCounts,
    this.initialize,
    this.addedRoleCardAmount = 1,
    this.roleCountAdjuster,
  });
}
