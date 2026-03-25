import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:werewolf_narrator/game/commands/mark_dead.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/death_information.dart';
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
  PyjamaPalRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  }) : dieIfAtHostile = config[dieIfAtHostileOptionKey];
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
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(OnAssignPyjamaPalCommand(playerIndex));
  }
}

class OnAssignPyjamaPalCommand implements GameCommand {
  const OnAssignPyjamaPalCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    gameData.nightActionManager.registerAction(
      PyjamaPalRole.type,
      (gameState, onComplete) => nightActionScreen(onComplete),
      players: {playerIndex},
      conditioned: (gameState) => gameState.playerAliveUntilDawn(playerIndex),
      before: IList([WitchRole.type, BigBadWolfRole.type, WerewolvesTeam.type]),
    );

    gameData.dawnHooks.add(dawnHook);

    gameData.deathHooks.add(deathHook);
  }

  @override
  bool get canBeUndone => false;

  @override
  void undo(GameData gameData) {
    // TODO: implement undo
    throw UnimplementedError();
  }

  WidgetBuilder nightActionScreen(VoidCallback onComplete) =>
      (BuildContext context) {
        return ActionScreen(
          key: UniqueKey(),
          actionIdentifier: PyjamaPalRole.type,
          appBarTitle: Text(PyjamaPalRole._name(context)),
          selectionCount: 1,
          currentActorIndices: ISet({playerIndex}),
          disabledPlayerIndices: ISet({playerIndex}),
          instruction: Text(
            AppLocalizations.of(context).role_pyjamaPal_nightAction_instruction,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          onConfirm: (playerIds, gameState) {
            gameState.apply(
              SetPyjamaPalSleepoverTargetCommand(
                playerIndex: playerIndex,
                sleepoverTargetIndex: playerIds.singleOrNull,
              ),
            );
            onComplete();
          },
        );
      };

  void dawnHook(GameState gameState, int dayCount) {
    final role = gameState.players[playerIndex].role as PyjamaPalRole;

    gameState.apply(
      CompositeGameCommand(
        <GameCommand>[
          if (role.dieIfAtHostile &&
              role.sleepoverAtPlayer != null &&
              gameState.players[role.sleepoverAtPlayer!].role?.team(
                    gameState,
                  ) ==
                  WerewolvesTeam.type)
            MarkDeadCommand.single(
              player: playerIndex,
              deathReason: WerewolvesDeathReason(
                WerewolvesTeam.werewolfPlayerIndices(gameState),
              ),
            ),

          SetPyjamaPalSleepoverTargetCommand(
            playerIndex: playerIndex,
            sleepoverTargetIndex: null,
          ),
        ].lock,
      ),
    );
  }

  bool deathHook(GameState gameState, int deadPlayerIndex, DeathReason reason) {
    final role = gameState.players[playerIndex].role as PyjamaPalRole;
    if (gameState.isNight) {
      if (role.sleepoverAtPlayer != null && deadPlayerIndex == playerIndex) {
        return true;
      }

      if (role.sleepoverAtPlayer == deadPlayerIndex) {
        gameState.apply(
          CompositeGameCommand(
            <GameCommand>[
              SetPyjamaPalSleepoverTargetCommand(
                playerIndex: playerIndex,
                sleepoverTargetIndex: null,
              ),
              MarkDeadCommand.single(player: playerIndex, deathReason: reason),
            ].lock,
          ),
        );
      }
    }
    return false;
  }
}

class SetPyjamaPalSleepoverTargetCommand implements GameCommand {
  const SetPyjamaPalSleepoverTargetCommand({
    required this.playerIndex,
    required this.sleepoverTargetIndex,
  });

  final int playerIndex;
  final int? sleepoverTargetIndex;

  @override
  void apply(GameData gameData) {
    final role = gameData.players[playerIndex].role as PyjamaPalRole;
    role.sleepoverAtPlayer = sleepoverTargetIndex;
  }

  @override
  bool get canBeUndone => false;

  @override
  void undo(GameData gameData) {
    // TODO: implement undo
    throw UnimplementedError();
  }
}
