import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam, WerewolvesDeathReason;
import 'package:werewolf_narrator/views/game/action_screen.dart';

class BigBadWolfRole extends Role {
  BigBadWolfRole._();
  static final RoleType type = RoleType<BigBadWolfRole>();
  @override
  RoleType get objectType => type;

  static void registerRole() {
    RoleManager.registerRole<BigBadWolfRole>(
      RegisterRoleInformation(
        constructor: BigBadWolfRole._,
        name: (context) => AppLocalizations.of(context).role_bigBadWolf_name,
        description: (context) =>
            AppLocalizations.of(context).role_bigBadWolf_description,
        initialTeam: WerewolvesTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_bigBadWolf_checkInstruction(count: count),
        validRoleCounts: const [1],
      ),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    gameState.nightActionManager.registerAction(
      BigBadWolfRole.type,
      (gameState, onComplete) => nightActionScreen(playerIndex, onComplete),
      conditioned: (gameState) =>
          gameState.playerAliveUntilDawn(playerIndex) &&
          !werewolfHasDied(gameState),
      after: [WerewolvesTeam.type],
      players: {playerIndex},
    );
  }

  WidgetBuilder nightActionScreen(int playerIndex, VoidCallback onComplete) =>
      (context) {
        final localizations = AppLocalizations.of(context);
        final gameState = Provider.of<GameState>(context, listen: false);

        final werewolfIndices = WerewolvesTeam.werewolfPlayerIndices(gameState);

        final deadIndices = gameState.players.indexed
            .where((player) => !player.$2.isAlive)
            .map((player) => player.$1)
            .toSet();

        final werewolvesOrDead = werewolfIndices.union(deadIndices);

        return ActionScreen(
          appBarTitle: Text(name(context)),
          instruction: Text(
            localizations.role_bigBadWolf_nightAction_instruction,
          ),
          selectionCount: 1,
          onConfirm: (selectedPlayers, gameState) {
            gameState.markPlayerDead(
              selectedPlayers.single,
              WerewolvesDeathReason({playerIndex}),
            );
            onComplete();
          },
          disabledPlayerIndices: werewolvesOrDead,
          currentActorIndices: {playerIndex},
        );
      };
}

bool werewolfHasDied(GameState gameState) => gameState.players.indexed
    .where((entry) => entry.$2.role?.team(gameState) == WerewolvesTeam.type)
    .map((entry) => entry.$1)
    .toSet()
    .intersection(gameState.knownDeadPlayerIndices)
    .isNotEmpty;
