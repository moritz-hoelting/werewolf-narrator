import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:werewolf_narrator/role/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/role/hunter.dart' show HunterRole;
import 'package:werewolf_narrator/role/little_girl.dart' show LittleGirlRole;
import 'package:werewolf_narrator/role/role.dart';
import 'package:werewolf_narrator/role/seer.dart' show SeerRole;
import 'package:werewolf_narrator/role/thief.dart' show ThiefRole;
import 'package:werewolf_narrator/role/villager.dart' show VillagerRole;
import 'package:werewolf_narrator/role/werewolf.dart' show WerewolfRole;
import 'package:werewolf_narrator/role/witch.dart' show WitchRole;
import 'package:werewolf_narrator/state/game.dart';

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

  /// The static instance of this role.
  Role get instance => RoleManager.getRoleInstance(this);

  /// The display name of this role.
  String name(BuildContext context) {
    return instance.name(context);
  }

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
    VillagerRole.registerRole();
    SeerRole.registerRole();
    WitchRole.registerRole();
    HunterRole.registerRole();
    CupidRole.registerRole();
    LittleGirlRole.registerRole();
    WerewolfRole.registerRole();
    ThiefRole.registerRole();
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

  /// Gets the static instance of the given role type.
  static Role getRoleInstance(RoleType role) {
    final info = _roleInformation[role];
    if (info != null) {
      return info.instance;
    } else {
      throw Exception('No instance registered for role type $role');
    }
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

  /// The static instance of this role.
  final Role instance;

  /// The initializer function for this role.
  final void Function(GameState gameState)? initialize;

  /// The role count adjuster function for this role.
  final void Function(Map<RoleType, int> roleCounts, int playerCount)?
  roleCountAdjuster;

  RegisterRoleInformation(
    this.constructor,
    this.instance, {
    this.initialize,
    this.roleCountAdjuster,
  });
}
