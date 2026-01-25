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

  Type get type => T;

  @override
  bool operator ==(Object other) => other is TeamType<T>;
  @override
  int get hashCode => T.hashCode;

  Team get instance => TeamManager.getTeamInstance(this);

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

  static void registerTeam<T extends Team>(RegisterTeamInformation<T> info) {
    if (_teamInformation.containsKey(TeamType<T>())) {
      throw Exception('Team of type $T is already registered');
    }
    _teamInformation[TeamType<T>()] = info;
  }

  static Team instantiateTeam(TeamType team) {
    final info = _teamInformation[team];
    if (info != null) {
      return info.constructor();
    } else {
      throw Exception('No constructor registered for team type $team');
    }
  }

  static Team getTeamInstance(TeamType team) {
    final info = _teamInformation[team];
    if (info != null) {
      return info.instance;
    } else {
      throw Exception('No instance registered for team type $team');
    }
  }

  static List<TeamType> get registeredTeams =>
      List.unmodifiable(_teamInformation.keys.toList());
}

class RegisterTeamInformation<T extends Team> {
  final Team Function() constructor;
  final Team instance;

  RegisterTeamInformation(this.constructor, this.instance);
}
