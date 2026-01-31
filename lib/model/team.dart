import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:werewolf_narrator/team/lovers.dart' show LoversTeam;
import 'package:werewolf_narrator/team/team.dart';
import 'package:werewolf_narrator/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/team/werewolves.dart' show WerewolvesTeam;

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

  /// The static instance of this team.
  Team get instance => TeamManager.getTeamInstance(this);

  /// The display name of this team.
  String name(BuildContext context) {
    return instance.name(context);
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
      _registerTeams();
      _registered = true;
    }
  }

  static void _registerTeams() {
    VillageTeam.registerTeam();
    WerewolvesTeam.registerTeam();
    LoversTeam.registerTeam();
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
  static Team getTeamInstance(TeamType team) {
    final info = _teamInformation[team];
    if (info != null) {
      return info.instance;
    } else {
      throw Exception('No instance registered for team type $team');
    }
  }

  /// The list of all registered team types.
  static List<TeamType> get registeredTeams =>
      List.unmodifiable(_teamInformation.keys.toList());
}

class RegisterTeamInformation<T extends Team> {
  /// The constructor function for this team.
  final Team Function() constructor;

  /// The static instance of this team.
  final Team instance;

  RegisterTeamInformation(this.constructor, this.instance);
}
