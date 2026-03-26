import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_annotations/register_team.dart' show RegisterTeam;
import 'package:werewolf_narrator/game/commands/mark_dead.dart';
import 'package:werewolf_narrator/game/commands/register_win_condition.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/role/village/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/game/role/village/seer.dart' show SeerRole;
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/game/model/win_condition.dart'
    show WinCondition, teamWinningPlayers;
import 'package:werewolf_narrator/game/role/werewolves/werewolf.dart'
    show WerewolfRole;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/team.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';

@RegisterTeam()
class WerewolvesTeam extends Team implements WinCondition {
  const WerewolvesTeam._();
  static final TeamType type = TeamType<WerewolvesTeam>();
  @override
  TeamType get objectType => type;

  static void registerTeam() {
    TeamManager.registerTeam<WerewolvesTeam>(
      RegisterTeamInformation(
        constructor: WerewolvesTeam._,
        name: _name,
        checkTeamTogether: TeamRoleCheckTogetherInformation(
          defaultRole: WerewolfRole.type,
          checkInstruction: (context, count) => AppLocalizations.of(
            context,
          ).team_werewolves_checkInstruction(count: count),
        ),
      ),
    );
  }

  @override
  void initialize(GameState gameState) {
    super.initialize(gameState);

    gameState.apply(
      CompositeGameCommand(
        [
          RegisterWinConditionCommand(this),
          RegisterWerewolvesNightActionCommand(),
        ].lock,
      ),
    );
  }

  static ISet<int> werewolfPlayerIndices(GameState gameState) => gameState
      .players
      .indexed
      .where((entry) => entry.$2.role?.team(gameState) == WerewolvesTeam.type)
      .map((entry) => entry.$1)
      .toISet();

  static String _name(BuildContext context) =>
      AppLocalizations.of(context).team_werewolves_name;

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context).team_werewolves_winHeadline;

  @override
  bool hasWon(GameState gameState) {
    final teamPlayers = gameState.players
        .where((player) => player.isAlive && player.role != null)
        .groupSetsBy((player) => player.role!.team(gameState));
    final werewolfCount = teamPlayers[WerewolvesTeam.type]?.length ?? 0;
    final teams = teamPlayers.keys.toSet();

    return (werewolfCount >= gameState.alivePlayerCount / 2 &&
        teams.difference({WerewolvesTeam.type, VillageTeam.type}).isEmpty);
  }

  @override
  ISet<int> winningPlayers(GameState gameState) =>
      teamWinningPlayers(gameState, objectType);
}

class WerewolvesDeathReason implements DeathReason {
  WerewolvesDeathReason(this.responsiblePlayers);

  final ISet<int> responsiblePlayers;

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).team_werewolves_deathReason;

  @override
  ISet<int> get responsiblePlayerIndices => responsiblePlayers;
}

class RegisterWerewolvesNightActionCommand implements GameCommand {
  Set<int> nightActionPlayerIndices = {};

  @override
  void apply(GameData gameData) {
    nightActionPlayerIndices = WerewolvesTeam.werewolfPlayerIndices(
      gameData.state,
    ).unlock;

    gameData.nightActionManager.registerAction(
      WerewolvesTeam.type,
      (gameState, onComplete) => nightActionScreen(onComplete),
      conditioned: (gameState) {
        nightActionPlayerIndices
          ..clear()
          ..addAll(WerewolvesTeam.werewolfPlayerIndices(gameState));
        return gameState.hasAlivePlayerOfTeamType<WerewolvesTeam>();
      },
      after: IList([CupidRole.type, SeerRole.type]),
      players: nightActionPlayerIndices,
    );
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    // TODO: implement undo
  }

  WidgetBuilder nightActionScreen(VoidCallback onComplete) => (context) {
    final localizations = AppLocalizations.of(context);
    final gameState = Provider.of<GameState>(context, listen: false);

    final werewolfIndices = WerewolvesTeam.werewolfPlayerIndices(gameState);

    final werewolvesOrDead = werewolfIndices.union(
      gameState.knownDeadPlayerIndices,
    );

    return ActionScreen(
      key: UniqueKey(),
      appBarTitle: Text(WerewolvesTeam._name(context)),
      instruction: Text(localizations.team_werewolves_nightAction_instruction),
      actionIdentifier: WerewolvesTeam.type,
      selectionCount: 1,
      allowSelectLess: true,
      currentActorIndices: werewolfIndices,
      disabledPlayerIndices: werewolvesOrDead,
      onConfirm: (selectedPlayers, gameState) {
        int? selectedPlayer = selectedPlayers.singleOrNull;
        if (selectedPlayer != null) {
          gameState.apply(
            MarkDeadCommand.single(
              player: selectedPlayer,
              deathReason: WerewolvesDeathReason(
                werewolfIndices.intersection(gameState.knownAlivePlayerIndices),
              ),
            ),
          );
        }
        onComplete();
      },
    );
  };
}
