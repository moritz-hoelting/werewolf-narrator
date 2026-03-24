import 'dart:collection';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
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

class DoctorRole extends Role {
  DoctorRole._(RoleConfiguration config)
    : protectPlayerCooldown = config[protectPlayerCooldownOptionKey];
  static final RoleType<DoctorRole> type = RoleType<DoctorRole>();
  @override
  RoleType<DoctorRole> get objectType => type;

  static const String protectPlayerCooldownOptionKey = "protectPlayerCooldown";

  final int protectPlayerCooldown;

  Queue<int> playersInCooldown = Queue();
  int? protectionTarget;

  static void registerRole() {
    RoleManager.registerRole<DoctorRole>(
      type,
      RegisterRoleInformation(
        constructor: DoctorRole._,
        name: _name,
        description: (context) =>
            AppLocalizations.of(context).role_doctor_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_doctor_checkInstruction(count: count),
        validRoleCounts: const [1],
        options: IList([
          IntOption(
            id: protectPlayerCooldownOptionKey,
            label: (context) => AppLocalizations.of(
              context,
            ).role_doctor_option_protectPlayerCooldown_label,
            description: (context) => AppLocalizations.of(
              context,
            ).role_doctor_option_protectPlayerCooldown_description,
            defaultValue: 0,
            min: 0,
          ),
        ]),
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.village,
          priority: 5,
        ),
      ),
    );
  }

  static String _name(BuildContext context) =>
      AppLocalizations.of(context).role_doctor_name;

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    gameState.nightActionManager.registerAction(
      DoctorRole.type,
      (gameState, onComplete) => nightActionScreen(playerIndex, onComplete),
      players: {playerIndex},
      conditioned: (gameState) => gameState.playerAliveUntilDawn(playerIndex),
      before: IList([WitchRole.type, BigBadWolfRole.type, WerewolvesTeam.type]),
    );

    gameState.dawnHooks.add((gameState, dayCount) {
      protectionTarget = null;
    });

    gameState.deathHooks.add(
      (gameState, deadPlayerIndex, reason) =>
          gameState.isNight && protectionTarget == deadPlayerIndex,
    );
  }

  WidgetBuilder nightActionScreen(int playerIndex, VoidCallback onComplete) =>
      (BuildContext context) {
        return ActionScreen(
          key: UniqueKey(),
          actionIdentifier: DoctorRole.type,
          appBarTitle: Text(_name(context)),
          selectionCount: 1,
          currentActorIndices: ISet({playerIndex}),
          disabledPlayerIndices: playersInCooldown.toISet(),
          instruction: Text(
            AppLocalizations.of(context).role_doctor_nightAction_instruction,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          onConfirm: (playerIds, gameState) {
            final protectPlayerIndex = playerIds.singleOrNull;
            if (protectPlayerIndex != null) {
              protectionTarget = protectPlayerIndex;
              addToCooldownList(protectPlayerIndex);
            }
            onComplete();
          },
        );
      };

  void addToCooldownList(int playerIndex) {
    playersInCooldown.add(playerIndex);
    while (playersInCooldown.length > protectPlayerCooldown) {
      playersInCooldown.removeFirst();
    }
  }
}
