import 'dart:collection';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/widgets.dart';
import 'package:werewolf_narrator/game/game_registry.g.dart' show GameRegistry;
import 'package:werewolf_narrator/game/model/role.dart' show RoleType;
import 'package:werewolf_narrator/game/team/team.dart';

part 'team.mapper.dart';

@MappableClass()
class TeamType with TeamTypeMappable {
  const TeamType._(this.id);

  @MappableConstructor()
  factory TeamType.fromId(String id) {
    GameRegistry.teamTypeForId(id); // Ensure that the team type is registered
    return TeamType._(id);
  }

  final String id;

  static final _teamMap = <String, TeamType>{};

  static TeamType of<T extends Team>() {
    final String id = GameRegistry.idForTeamType<T>();
    if (!_teamMap.containsKey(id)) {
      _teamMap[id] = TeamType._(id);
    }
    return _teamMap[id]!;
  }

  /// The unique type of this team.
  Type get type => GameRegistry.teamTypeForId(id);

  @override
  bool operator ==(Object other) => other is TeamType ? other.id == id : false;
  @override
  int get hashCode => type.hashCode;

  /// The registered information for this team.
  RegisterTeamInformation get information => TeamManager.getInformation(this);

  /// The display name of this team.
  String name(BuildContext context) {
    return information.name(context);
  }

  @override
  String toString() => 'Team<$id>';
}

abstract class TeamManager {
  static final LinkedHashMap<TeamType, RegisterTeamInformation>
  _teamInformation = LinkedHashMap();

  /// Registers a team with the given information.
  static void registerTeam<T extends Team>(
    TeamType teamType,
    RegisterTeamInformation<T> info,
  ) {
    assert(
      teamType == TeamType.of<T>(),
      'The team type must match the team information',
    );
    if (_teamInformation.containsKey(teamType)) {
      throw Exception('Team of type $T is already registered');
    }
    _teamInformation[teamType] = info;
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
