import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/views/game/action_screen.dart';

class BigBadWolfRole extends Role {
  BigBadWolfRole._();
  static final RoleType type = RoleType<BigBadWolfRole>();
  @override
  RoleType get objectType => type;

  static final Role instance = BigBadWolfRole._();

  static void registerRole() {
    RoleManager.registerRole<BigBadWolfRole>(
      RegisterRoleInformation(BigBadWolfRole._, instance),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    gameState.nightActionManager.registerAction(
      BigBadWolfRole.type,
      (gameState, onComplete) => nightActionScreen(onComplete),
      conditioned: (gameState) =>
          gameState.playerAliveUntilDawn(playerIndex) &&
          !werewolfHasDied(gameState),
      after: [WerewolvesTeam.type],
    );
  }

  @override
  bool get isUnique => true;
  @override
  TeamType get initialTeam => WerewolvesTeam.type;

  @override
  String name(BuildContext context) {
    return AppLocalizations.of(context).role_bigBadWolf_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context).role_bigBadWolf_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    return AppLocalizations.of(
      context,
    ).role_bigBadWolf_checkInstruction(count: count);
  }

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
      appBarTitle: Text(BigBadWolfRole.instance.name(context)),
      instruction: Text(localizations.role_bigBadWolf_nightAction_instruction),
      selectionCount: 1,
      onConfirm: (selectedPlayers, gameState) {
        gameState.markPlayerDead(
          selectedPlayers.first,
          (gameState.teams[WerewolvesTeam.type] as WerewolvesTeam),
        );
        onComplete();
      },
      disabledPlayerIndices: werewolvesOrDead,
    );
  };
}

bool werewolfHasDied(GameState gameState) => gameState.players.indexed
    .where((entry) => entry.$2.role?.team(gameState) == WerewolvesTeam.type)
    .map((entry) => entry.$1)
    .toSet()
    .intersection(gameState.knownDeadPlayerIndices)
    .isNotEmpty;
