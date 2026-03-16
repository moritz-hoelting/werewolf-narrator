import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/game/role/village/doctor.dart'
    show DoctorRole;
import 'package:werewolf_narrator/game/role/village/witch.dart' show WitchRole;
import 'package:werewolf_narrator/game/role/werewolves/big_bad_wolf.dart'
    show BigBadWolfRole;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/views/game/action_screen.dart';

class BodyguardRole extends Role {
  BodyguardRole._(RoleConfiguration config);
  static final RoleType<BodyguardRole> type = RoleType<BodyguardRole>();
  @override
  RoleType<BodyguardRole> get objectType => type;

  bool hasBeenAttacked = false;
  int? protectionTarget;

  late final int playerIndex;

  static void registerRole() {
    RoleManager.registerRole<BodyguardRole>(
      type,
      RegisterRoleInformation(
        constructor: BodyguardRole._,
        name: _name,
        description: (context) =>
            AppLocalizations.of(context).role_bodyguard_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_bodyguard_checkInstruction(count: count),
        validRoleCounts: const [1],
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 5,
        ),
      ),
    );
  }

  static String _name(BuildContext context) =>
      AppLocalizations.of(context).role_bodyguard_name;

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    this.playerIndex = playerIndex;

    gameState.nightActionManager.registerAction(
      BodyguardRole.type,
      (gameState, onComplete) => nightActionScreen(playerIndex, onComplete),
      players: {playerIndex},
      conditioned: (gameState) => gameState.playerAliveUntilDawn(playerIndex),
      before: IList([WitchRole.type, BigBadWolfRole.type, WerewolvesTeam.type]),
      after: IList([DoctorRole.type]),
    );

    gameState.dawnHooks.add((gameState, dayCount) {
      protectionTarget = null;
    });

    gameState.deathHooks.add(deathHook);
  }

  bool deathHook(GameState gameState, int deadPlayerIndex, DeathReason reason) {
    if (hasBeenAttacked && deadPlayerIndex != playerIndex) {
      gameState.markPlayerDead(playerIndex, reason);
    }
    if (gameState.isNight &&
        protectionTarget == deadPlayerIndex &&
        gameState.playerAliveUntilDawn(playerIndex)) {
      hasBeenAttacked = true;
      return true;
    } else if (deadPlayerIndex == playerIndex) {
      final bool wasProtected = !hasBeenAttacked;
      if (hasBeenAttacked) {
        gameState.deathHooks.remove(deathHook);
      }
      hasBeenAttacked = true;
      return wasProtected;
    } else {
      return false;
    }
  }

  WidgetBuilder nightActionScreen(int playerIndex, VoidCallback onComplete) =>
      (BuildContext context) {
        // TODO: show when the bodyguard has already been attacked
        return ActionScreen(
          key: UniqueKey(),
          actionIdentifier: BodyguardRole.type,
          appBarTitle: Text(_name(context)),
          selectionCount: 1,
          currentActorIndices: ISet({playerIndex}),
          instruction: Text(
            AppLocalizations.of(context).role_bodyguard_nightAction_instruction,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          onConfirm: (playerIds, gameState) {
            protectionTarget = playerIds.singleOrNull;
            onComplete();
          },
        );
      };
}
