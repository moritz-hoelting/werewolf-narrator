import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;
import 'package:werewolf_narrator/game/model/player.dart';
import 'package:werewolf_narrator/game/model/role.dart';
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

class WerewolvesTeam extends Team implements DeathReason, WinCondition {
  const WerewolvesTeam._();
  static final TeamType type = TeamType<WerewolvesTeam>();
  @override
  TeamType get objectType => type;
  static const Team instance = WerewolvesTeam._();

  static void registerTeam() {
    TeamManager.registerTeam<WerewolvesTeam>(
      RegisterTeamInformation(WerewolvesTeam._, instance),
    );
  }

  @override
  void initialize(GameState gameState) {
    super.initialize(gameState);

    gameState.winConditions.add(this);

    gameState.nightActionManager.registerAction(
      WerewolvesTeam.type,
      (gameState, onComplete) => nightActionScreen(onComplete),
      conditioned: (gameState) =>
          gameState.hasAlivePlayerOfTeamType<WerewolvesTeam>(),
      after: [CupidRole.type, SeerRole.type],
    );
  }

  @override
  RoleType? get roleCheckTogether => WerewolfRole.type;

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context).team_werewolves_name;

  @override
  String checkTeamInstruction(BuildContext context, int count) {
    final localizations = AppLocalizations.of(context);
    return localizations.team_werewolves_checkInstruction(count: count);
  }

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context).team_werewolves_winHeadline;

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).team_werewolves_deathReason;

  WidgetBuilder nightActionScreen(VoidCallback onComplete) => (context) {
    final localizations = AppLocalizations.of(context);
    final gameState = Provider.of<GameState>(context, listen: false);

    final werewolfIndices = gameState.players.indexed
        .where(
          (player) => player.$2.role?.team(gameState) == WerewolvesTeam.type,
        )
        .map((player) => player.$1)
        .toSet();

    final deadIndices = gameState.players.indexed
        .where((player) => !player.$2.isAlive)
        .map((player) => player.$1)
        .toSet();

    final werewolvesOrDead = werewolfIndices.union(deadIndices);

    return ActionScreen(
      appBarTitle: Text(name(context)),
      instruction: Text(localizations.team_werewolves_nightAction_instruction),
      selectionCount: 1,
      currentActorIndices: werewolfIndices,
      disabledPlayerIndices: werewolvesOrDead,
      onConfirm: (selectedPlayers, gameState) {
        gameState.markPlayerDead(selectedPlayers.single, this);
        onComplete();
      },
    );
  };

  @override
  bool hasWon(GameState gameState) => setEquals(
    gameState.players
        .where((player) => player.isAlive)
        .map((player) => player.role?.team(gameState))
        .toSet(),
    {WerewolvesTeam.type},
  );

  @override
  List<(int, Player)> winningPlayers(GameState gameState) =>
      teamWinningPlayers(gameState, objectType);
}
