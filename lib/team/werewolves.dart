import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/model/team.dart';
import 'package:werewolf_narrator/role/cupid.dart' show CupidRole;
import 'package:werewolf_narrator/role/seer.dart' show SeerRole;
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/team/team.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';

class WerewolvesTeam extends Team {
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

    gameState.nightActionManager.registerAction(
      WerewolvesTeam.type,
      (gameState, onComplete) {
        return nightActionScreen(onComplete);
      },
      conditioned: (gameState) =>
          gameState.hasAlivePlayerOfTeamType<WerewolvesTeam>(),
      after: [CupidRole.type, SeerRole.type],
    );
  }

  @override
  String name(BuildContext context) =>
      AppLocalizations.of(context)!.team_werewolves_name;

  @override
  String winningHeadline(BuildContext context) =>
      AppLocalizations.of(context)!.team_werewolves_winHeadline;

  WidgetBuilder nightActionScreen(VoidCallback onComplete) => (context) {
    final localizations = AppLocalizations.of(context)!;
    final gameState = Provider.of<GameState>(context, listen: false);
    final werewolvesOrDead = gameState.players.indexed
        .where(
          (player) =>
              player.$2.role?.team(gameState) == WerewolvesTeam.type ||
              !player.$2.isAlive,
        )
        .map((player) => player.$1)
        .toSet();
    return ActionScreen(
      appBarTitle: Text(localizations.role_werewolf_name),
      instruction: Text(localizations.screen_roleAction_instruction_werewolf),
      selectionCount: 1,
      disabledPlayerIndices: werewolvesOrDead,
      onConfirm: (selectedPlayers, gameState) {
        gameState.markPlayerDead(selectedPlayers.first, DeathReason.werewolf);
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
}
