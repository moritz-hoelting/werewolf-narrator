import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:werewolf_narrator/game/game_registry.g.dart' show GameRegistry;
import 'package:werewolf_narrator/game/model/role.dart' show RoleType;
import 'package:werewolf_narrator/game/team/team.dart';

class TeamType<T extends Team> {
  const TeamType._();

  static final _teamMap = <Type, TeamType>{};

  factory TeamType() {
    if (!_teamMap.containsKey(T)) {
      _teamMap[T] = TeamType<T>._();
    }
    return _teamMap[T] as TeamType<T>;
  }

  /// The unique type of this team.
  Type get type => T;

  @override
  bool operator ==(Object other) => other is TeamType<T>;
  @override
  int get hashCode => T.hashCode;

  /// The registered information for this team.
  RegisterTeamInformation get information => TeamManager.getInformation(this);

  /// The display name of this team.
  String name(BuildContext context) {
    return information.name(context);
  }

  @override
  String toString() => 'Team<$T>';
}

abstract class TeamManager {
  static final LinkedHashMap<TeamType, RegisterTeamInformation>
  _teamInformation = LinkedHashMap();
  static bool _registered = false;

  /// Ensures that all teams are registered.
  static void ensureRegistered() {
    if (!_registered) {
      GameRegistry.registerTeams();
      _registered = true;
    }
  }

  /// Registers a team with the given information.
  static void registerTeam<T extends Team>(RegisterTeamInformation<T> info) {
    if (_teamInformation.containsKey(TeamType<T>())) {
      throw Exception('Team of type $T is already registered');
    }
    _teamInformation[TeamType<T>()] = info;
  }

  /// Instantiates a new team of the given type.
  static Team instantiateTeam(TeamType team) {
    final info = _teamInformation[team];
    if (info != null) {
      return info.constructor();
    } else {
      throw Exception('No constructor registered for team type $team');
    }
  }

  /// Gets the static instance of the given team type.
  static RegisterTeamInformation getInformation(TeamType team) {
    final info = _teamInformation[team];
    if (info != null) {
      return info;
    } else {
      throw Exception('No information registered for team type $team');
    }
  }

  /// The list of all registered team types.
  static List<TeamType> get registeredTeams =>
      List.unmodifiable(_teamInformation.keys.toList());
}

class RegisterTeamInformation<T extends Team> {
  /// The constructor function for this team.
  final Team Function() constructor;

  /// The name of this team.
  String Function(BuildContext context) name;

  /// The check instruction for this team.
  TeamRoleCheckTogetherInformation? checkTeamTogether;

  RegisterTeamInformation({
    required this.constructor,
    required this.name,
    this.checkTeamTogether,
  });
}

class TeamRoleCheckTogetherInformation {
  RoleType defaultRole;
  String Function(BuildContext context, int count) checkInstruction;

  TeamRoleCheckTogetherInformation({
    required this.defaultRole,
    required this.checkInstruction,
  });
}
