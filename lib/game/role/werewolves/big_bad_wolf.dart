import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/role/village/witch.dart' show WitchRole;
import 'package:werewolf_narrator/game/role/werewolves/ancient_werewolf.dart'
    show AncientWerewolfRole;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam, WerewolvesDeathReason;
import 'package:werewolf_narrator/views/game/action_screen.dart';

class BigBadWolfRole extends Role {
  BigBadWolfRole._(RoleConfiguration config);
  static final RoleType<BigBadWolfRole> type = RoleType<BigBadWolfRole>();
  @override
  RoleType<BigBadWolfRole> get objectType => type;

  static void registerRole() {
    RoleManager.registerRole<BigBadWolfRole>(
      type,
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
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.werewolves,
          priority: 5,
        ),
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
      after: IList([WerewolvesTeam.type, AncientWerewolfRole.type]),
      before: IList([WitchRole.type]),
      players: {playerIndex},
    );
  }

  WidgetBuilder nightActionScreen(int playerIndex, VoidCallback onComplete) =>
      (context) {
        final localizations = AppLocalizations.of(context);
        final gameState = Provider.of<GameState>(context, listen: false);

        final werewolfIndices = WerewolvesTeam.werewolfPlayerIndices(gameState);

        final werewolvesOrDead = werewolfIndices.union(
          gameState.knownDeadPlayerIndices,
        );

        return ActionScreen(
          appBarTitle: Text(name(context)),
          instruction: Text(
            localizations.role_bigBadWolf_nightAction_instruction,
          ),
          actionIdentifier: BigBadWolfRole.type,
          selectionCount: 1,
          onConfirm: (selectedPlayers, gameState) {
            gameState.markPlayerDead(
              selectedPlayers.single,
              WerewolvesDeathReason(ISet({playerIndex})),
            );
            onComplete();
          },
          disabledPlayerIndices: werewolvesOrDead,
          currentActorIndices: ISet({playerIndex}),
        );
      };
}

bool werewolfHasDied(GameState gameState) => gameState.players.indexed
    .where((entry) => entry.$2.role?.team(gameState) == WerewolvesTeam.type)
    .map((entry) => entry.$1)
    .toISet()
    .intersection(gameState.knownDeadPlayerIndices)
    .isNotEmpty;
