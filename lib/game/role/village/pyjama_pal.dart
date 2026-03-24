import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/role/village/witch.dart' show WitchRole;
import 'package:werewolf_narrator/game/role/werewolves/big_bad_wolf.dart'
    show BigBadWolfRole;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesDeathReason, WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/views/game/action_screen.dart';

class PyjamaPalRole extends Role {
  PyjamaPalRole._(RoleConfiguration config)
    : dieIfAtHostile = config[dieIfAtHostileOptionKey];
  static final RoleType<PyjamaPalRole> type = RoleType<PyjamaPalRole>();
  @override
  RoleType<PyjamaPalRole> get objectType => type;

  static const String dieIfAtHostileOptionKey = "dieIfAtHostile";

  final bool dieIfAtHostile;

  int? sleepoverAtPlayer;

  static void registerRole() {
    RoleManager.registerRole<PyjamaPalRole>(
      type,
      RegisterRoleInformation(
        constructor: PyjamaPalRole._,
        name: _name,
        description: (context) =>
            AppLocalizations.of(context).role_pyjamaPal_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_pyjamaPal_checkInstruction(count: count),
        validRoleCounts: const [1],
        options: IList([
          BoolOption(
            id: dieIfAtHostileOptionKey,
            label: (context) => AppLocalizations.of(
              context,
            ).role_pyjamaPal_option_dieIfAtHostile_label,
            description: (context) => AppLocalizations.of(
              context,
            ).role_pyjamaPal_option_dieIfAtHostile_description,
          ),
        ]),
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.village,
        ),
      ),
    );
  }

  static String _name(BuildContext context) =>
      AppLocalizations.of(context).role_pyjamaPal_name;

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    gameState.nightActionManager.registerAction(
      PyjamaPalRole.type,
      (gameState, onComplete) => nightActionScreen(playerIndex, onComplete),
      players: {playerIndex},
      conditioned: (gameState) => gameState.playerAliveUntilDawn(playerIndex),
      before: IList([WitchRole.type, BigBadWolfRole.type, WerewolvesTeam.type]),
    );

    gameState.dawnHooks.add((gameState, dayCount) {
      if (dieIfAtHostile &&
          sleepoverAtPlayer != null &&
          gameState.players[sleepoverAtPlayer!].role?.team(gameState) ==
              WerewolvesTeam.type) {
        gameState.markPlayerDead(
          playerIndex,
          WerewolvesDeathReason(
            WerewolvesTeam.werewolfPlayerIndices(gameState),
          ),
        );
      }

      sleepoverAtPlayer = null;
    });

    gameState.deathHooks.add((gameState, deadPlayerIndex, reason) {
      if (gameState.isNight) {
        if (sleepoverAtPlayer != null && deadPlayerIndex == playerIndex) {
          return true;
        }

        if (sleepoverAtPlayer == deadPlayerIndex) {
          sleepoverAtPlayer = null;
          gameState.markPlayerDead(playerIndex, reason);
        }
      }
      return false;
    });
  }

  WidgetBuilder nightActionScreen(int playerIndex, VoidCallback onComplete) =>
      (BuildContext context) {
        return ActionScreen(
          key: UniqueKey(),
          actionIdentifier: PyjamaPalRole.type,
          appBarTitle: Text(_name(context)),
          selectionCount: 1,
          currentActorIndices: ISet({playerIndex}),
          disabledPlayerIndices: ISet({playerIndex}),
          instruction: Text(
            AppLocalizations.of(context).role_pyjamaPal_nightAction_instruction,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          onConfirm: (playerIds, gameState) {
            sleepoverAtPlayer = playerIds.singleOrNull;
            onComplete();
          },
        );
      };
}
