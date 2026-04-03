import 'package:dart_mappable/dart_mappable.dart';
import 'package:werewolf_annotations/register_team.dart' show RegisterTeam;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';
import 'package:werewolf_narrator/game/commands/register_win_condition.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/game/model/win_condition.dart'
    show WinCondition, teamWinningPlayers, WinConditionMapper;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/team.dart';

part 'village.mapper.dart';

@RegisterTeam()
class VillageTeam extends Team {
  const VillageTeam._();
  static final TeamType type = TeamType.of<VillageTeam>();
  @override
  TeamType get teamType => type;

  static void registerTeam() {
    TeamManager.registerTeam<VillageTeam>(
      type,
      RegisterTeamInformation(
        constructor: VillageTeam._,
        name: (context) => AppLocalizations.of(context).team_village_name,
      ),
    );
  }

  @override
  void initialize(GameState gameState) {
    super.initialize(gameState);

    gameState.apply(RegisterWinConditionCommand(VillageWinCondition()));
  }
}

@MappableClass(discriminatorValue: 'village')
class VillageWinCondition
    with VillageWinConditionMappable
    implements WinCondition {
  const VillageWinCondition();

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context).team_village_winHeadline;

  @override
  bool hasWon(GameState gameState) => setEquals(
    gameState.players
        .where((player) => player.isAlive)
        .map((player) => player.role?.team(gameState))
        .toSet(),
    {VillageTeam.type},
  );

  @override
  ISet<int> winningPlayers(GameState gameState) =>
      teamWinningPlayers(gameState, VillageTeam.type);
}
