import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:werewolf_narrator/role/role.dart';
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

  Type get type => T;

  @override
  bool operator ==(Object other) => other is RoleType<T>;
  @override
  int get hashCode => T.hashCode;

  Role get instance => RoleManager.getRoleInstance(this);

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

  static void registerRole<T extends Role>(RegisterRoleInformation<T> info) {
    if (_roleInformation.containsKey(RoleType<T>())) {
      throw Exception('Role of type $T is already registered');
    }
    _roleInformation[RoleType<T>()] = info;
  }

  static Role instantiateRole(RoleType role) {
    final info = _roleInformation[role];
    if (info != null) {
      return info.constructor();
    } else {
      throw Exception('No constructor registered for role type $role');
    }
  }

  static Role getRoleInstance(RoleType role) {
    final info = _roleInformation[role];
    if (info != null) {
      return info.instance;
    } else {
      throw Exception('No instance registered for role type $role');
    }
  }

  static List<RoleType> get registeredRoles =>
      List.unmodifiable(_roleInformation.keys.toList());

  static void Function(GameState gameState)? getInitializer(RoleType role) {
    final info = _roleInformation[role];
    return info?.initialize;
  }

  static void Function(Map<RoleType, int> roleCounts, int playerCount)?
  getRoleCountAdjuster(RoleType role) {
    final info = _roleInformation[role];
    return info?.roleCountAdjuster;
  }
}

class RegisterRoleInformation<T extends Role> {
  final Role Function() constructor;
  final Role instance;

  final void Function(GameState gameState)? initialize;
  final void Function(Map<RoleType, int> roleCounts, int playerCount)?
  roleCountAdjuster;

  RegisterRoleInformation(
    this.constructor,
    this.instance, {
    this.initialize,
    this.roleCountAdjuster,
  });
}
