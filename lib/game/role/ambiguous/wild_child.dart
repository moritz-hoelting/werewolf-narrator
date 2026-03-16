import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/game/team/team.dart';
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/views/game/action_screen.dart';

class WildChildRole extends Role {
  WildChildRole._(RoleConfiguration config);

  static final RoleType<WildChildRole> type = RoleType<WildChildRole>();
  @override
  RoleType<WildChildRole> get objectType => type;

  int? roleModel;
  bool turned = false;

  @override
  String name(BuildContext context) {
    if (turned) {
      return AppLocalizations.of(context).role_wildChild_name_turned;
    }
    return super.name(context);
  }

  @override
  TeamType<Team>? team(GameState gameState) => overrideTeam.getOrElse(() {
    if (turned) {
      return WerewolvesTeam.type;
    }
    return super.team(gameState);
  });

  static void registerRole() {
    RoleManager.registerRole<WildChildRole>(
      type,
      RegisterRoleInformation(
        constructor: WildChildRole._,
        name: (context) => AppLocalizations.of(context).role_wildChild_name,
        description: (context) =>
            AppLocalizations.of(context).role_wildChild_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_wildChild_checkInstruction(count: count),
        validRoleCounts: const [1],
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.ambiguous,
          priority: 2,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    gameState.nightActionManager.registerAction(
      WildChildRole.type,
      (gameState, onComplete) {
        return nightActionScreen(playerIndex, onComplete);
      },
      conditioned: (gameState) =>
          gameState.playerAliveUntilDawn(playerIndex) && roleModel == null,
      players: {playerIndex},
    );
  }

  WidgetBuilder nightActionScreen(int playerIndex, VoidCallback onComplete) =>
      (context) {
        final localizations = AppLocalizations.of(context);
        return ActionScreen(
          key: UniqueKey(),
          appBarTitle: Text(localizations.role_wildChild_name),
          instruction: Text(
            localizations.role_wildChild_nightAction_instruction,
          ),
          actionIdentifier: WildChildRole,
          selectionCount: 1,
          currentActorIndices: ISet({playerIndex}),
          disabledPlayerIndices: ISet({playerIndex}),
          onConfirm: (selectedIndices, gameState) {
            roleModel = selectedIndices.single;

            if (!gameState.players[roleModel!].isAlive) {
              turned = true;
            } else {
              gameState.deathHooks.add((gameState, index, reason) {
                if (index == roleModel) {
                  turned = true;
                }

                return false;
              });
            }

            onComplete();
          },
        );
      };
}
