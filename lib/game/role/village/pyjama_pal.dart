import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/commands/composite.dart';
import 'package:werewolf_narrator/game/commands/mark_dead.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/configuration_options.dart';
import 'package:werewolf_narrator/game/model/death_information.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/role/village/witch.dart' show WitchRole;
import 'package:werewolf_narrator/game/role/werewolves/big_bad_wolf.dart'
    show BigBadWolfRole;
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesDeathReason, WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';

part 'pyjama_pal.mapper.dart';

@RegisterRole()
class PyjamaPalRole extends Role {
  PyjamaPalRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  }) : dieIfAtHostile = dieIfAtHostileOption.read(config);
  static final RoleType type = RoleType.of<PyjamaPalRole>();
  @override
  RoleType get roleType => type;

  static final dieIfAtHostileOption = BoolOption(
    id: 'dieIfAtHostile',
    label: (context) =>
        AppLocalizations.of(context).role_pyjamaPal_option_dieIfAtHostile_label,
    description: (context) => AppLocalizations.of(
      context,
    ).role_pyjamaPal_option_dieIfAtHostile_description,
  );

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
        options: IList([dieIfAtHostileOption]),
        chooseRolesInformation: const ChooseRolesInformation(
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

@MappableClass(discriminatorValue: 'onAssignPyjamaPal')
class OnAssignPyjamaPalCommand
    with OnAssignPyjamaPalCommandMappable
    implements GameCommand {
  const OnAssignPyjamaPalCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    gameData.nightActionManager.registerAction(
      PyjamaPalRole.type,
      (gameState, onComplete) => nightActionScreen(onComplete),
      players: {playerIndex},
      conditioned: (gameState) => gameState.players[playerIndex].isAlive,
      before: ISet({WitchRole.type, BigBadWolfRole.type, WerewolvesTeam.type}),
    );

    gameData.dawnHooks.add(dawnHook);
    gameData.deathHooks.add(deathHook);
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.nightActionManager.unregisterAction(PyjamaPalRole.type);

    gameData.dawnHooks.remove(dawnHook);
    gameData.deathHooks.remove(deathHook);
  }

  WidgetBuilder nightActionScreen(VoidCallback onComplete) =>
      (BuildContext context) => ActionScreen(
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

  bool deathHook(
    GameState gameState,
    int deadPlayerIndex,
    DeathInformation information,
  ) {
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
              MarkDeadCommand.single(
                player: playerIndex,
                deathReason: PyjamaPalSleepoverAtPlayerDeathReason(
                  ISet(information.reason.responsiblePlayerIndices),
                ),
              ),
            ].lock,
          ),
        );
      }
    }
    return false;
  }
}

@MappableClass(discriminatorValue: 'pyjamaPalSleepoverAtPlayerDeath')
class PyjamaPalSleepoverAtPlayerDeathReason
    with PyjamaPalSleepoverAtPlayerDeathReasonMappable
    implements DeathReason {
  PyjamaPalSleepoverAtPlayerDeathReason(this.responsiblePlayers);

  final ISet<int> responsiblePlayers;

  @override
  String deathReasonDescription(BuildContext context) =>
      AppLocalizations.of(context).role_pyjamaPal_deathReason;

  @override
  ISet<int> get responsiblePlayerIndices => responsiblePlayers;
}

@MappableClass(discriminatorValue: 'setPyjamaPalSleepoverTarget')
class SetPyjamaPalSleepoverTargetCommand
    with SetPyjamaPalSleepoverTargetCommandMappable
    implements GameCommand {
  final int playerIndex;
  final int? sleepoverTargetIndex;

  SetPyjamaPalSleepoverTargetCommand({
    required this.playerIndex,
    required this.sleepoverTargetIndex,
  });

  Option<int?> _previousSleepoverTargetIndex = const Option.none();

  @override
  void apply(GameData gameData) {
    final role = gameData.players[playerIndex].role as PyjamaPalRole;
    _previousSleepoverTargetIndex = Option.of(role.sleepoverAtPlayer);
    role.sleepoverAtPlayer = sleepoverTargetIndex;
  }

  @override
  bool get canBeUndone => _previousSleepoverTargetIndex.isSome();

  @override
  void undo(GameData gameData) {
    final role = gameData.players[playerIndex].role as PyjamaPalRole;
    role.sleepoverAtPlayer = _previousSleepoverTargetIndex.getOrElse(
      () => null,
    );
    _previousSleepoverTargetIndex = const Option.none();
  }
}
