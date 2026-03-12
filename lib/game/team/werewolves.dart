import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;
import 'package:werewolf_narrator/game/model/player.dart';
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/game/model/win_condition.dart'
    show WinCondition, teamWinningPlayers;
import 'package:werewolf_narrator/game/role/village/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/game/role/village/seer.dart' show SeerRole;
import 'package:werewolf_narrator/game/role/werewolves/werewolf.dart'
    show WerewolfRole;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/team.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';

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

    gameState.winConditions.add(this);

    final nightActionPlayerIndices = werewolfPlayerIndices(gameState);

    gameState.nightActionManager.registerAction(
      WerewolvesTeam.type,
      (gameState, onComplete) => nightActionScreen(onComplete),
      conditioned: (gameState) {
        nightActionPlayerIndices
          ..clear()
          ..addAll(werewolfPlayerIndices(gameState));
        return gameState.hasAlivePlayerOfTeamType<WerewolvesTeam>();
      },
      after: [CupidRole.type, SeerRole.type],
      players: nightActionPlayerIndices,
    );
  }

  static Set<int> werewolfPlayerIndices(GameState gameState) => gameState
      .players
      .indexed
      .where((entry) => entry.$2.role?.team(gameState) == WerewolvesTeam.type)
      .map((entry) => entry.$1)
      .toSet();

  static String _name(BuildContext context) =>
      AppLocalizations.of(context).team_werewolves_name;

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context).team_werewolves_winHeadline;

  WidgetBuilder nightActionScreen(VoidCallback onComplete) => (context) {
    final localizations = AppLocalizations.of(context);
    final gameState = Provider.of<GameState>(context, listen: false);

    final werewolfIndices = werewolfPlayerIndices(gameState);

    final deadIndices = gameState.players.indexed
        .where((player) => !player.$2.isAlive)
        .map((player) => player.$1)
        .toSet();

    final werewolvesOrDead = werewolfIndices.union(deadIndices);

    return ActionScreen(
      key: UniqueKey(),
      appBarTitle: Text(_name(context)),
      instruction: Text(localizations.team_werewolves_nightAction_instruction),
      selectionCount: 1,
      currentActorIndices: werewolfIndices,
      disabledPlayerIndices: werewolvesOrDead,
      onConfirm: (selectedPlayers, gameState) {
        gameState.markPlayerDead(
          selectedPlayers.single,
          WerewolvesDeathReason(
            werewolfIndices.intersection(gameState.knownAlivePlayerIndices),
          ),
        );
        onComplete();
      },
    );
  };

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
  List<(int, Player)> winningPlayers(GameState gameState) =>
      teamWinningPlayers(gameState, objectType);
}

class WerewolvesDeathReason implements DeathReason {
  WerewolvesDeathReason(this.responsiblePlayers);

  final Set<int> responsiblePlayers;

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).team_werewolves_deathReason;

  @override
  Set<int> get responsiblePlayerIndices => responsiblePlayers;
}
