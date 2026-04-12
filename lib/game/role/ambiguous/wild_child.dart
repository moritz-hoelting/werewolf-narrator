import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/configuration_options.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/team.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game/action_screen.dart';

part 'wild_child.mapper.dart';

@RegisterRole()
class WildChildRole extends Role {
  WildChildRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  });

  static final RoleType type = RoleType.of<WildChildRole>();
  @override
  RoleType get roleType => type;

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
  TeamType? team(GameState gameState) => overrideTeam.getOrElse(() {
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
        chooseRolesInformation: const ChooseRolesInformation(
          category: ChooseRolesCategory.ambiguous,
          priority: 2,
        ),
      ),
    );
  }

  @override
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(RegisterWildChildNightActionCommand(playerIndex));
  }
}

@MappableClass(discriminatorValue: 'registerWildChildNightAction')
class RegisterWildChildNightActionCommand
    with RegisterWildChildNightActionCommandMappable
    implements GameCommand {
  const RegisterWildChildNightActionCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    gameData.nightActionManager.registerAction(
      WildChildRole.type,
      (gameState, onComplete) => nightActionScreen(playerIndex, onComplete),
      conditioned: (gameState) =>
          gameState.playerAliveUntilDawn(playerIndex) &&
          (gameState.players[playerIndex].role as WildChildRole).roleModel ==
              null,
      players: {playerIndex},
    );
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.nightActionManager.unregisterAction(WildChildRole.type);
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
            final int roleModel = selectedIndices.single;

            gameState.apply(
              WildChildSelectRoleModelCommand(
                playerIndex: playerIndex,
                roleModelIndex: roleModel,
              ),
            );

            onComplete();
          },
        );
      };
}

@MappableClass(discriminatorValue: 'wildChildSelectRoleModel')
class WildChildSelectRoleModelCommand
    with WildChildSelectRoleModelCommandMappable
    implements GameCommand {
  final int playerIndex;
  final int roleModelIndex;

  WildChildSelectRoleModelCommand({
    required this.playerIndex,
    required this.roleModelIndex,
  });

  ({int? roleModel, bool turned})? _previousData;

  @override
  void apply(GameData gameData) {
    final player = gameData.players[playerIndex];
    final role = player.role as WildChildRole;

    _previousData = (roleModel: role.roleModel, turned: role.turned);

    role.roleModel = roleModelIndex;
    if (!gameData.players[roleModelIndex].isAlive) {
      role.turned = true;
    } else {
      gameData.deathHooks.add(deathHook);
    }
  }

  @override
  bool get canBeUndone => _previousData != null;

  @override
  void undo(GameData gameData) {
    final player = gameData.players[playerIndex];
    final role = player.role as WildChildRole;

    if (_previousData!.roleModel == null) {
      gameData.deathHooks.remove(deathHook);
    }

    final (:roleModel, :turned) = _previousData!;

    role.roleModel = roleModel;
    role.turned = turned;

    _previousData = null;
  }

  bool deathHook(GameState gameState, int index, DeathReason reason) {
    if (index == roleModelIndex) {
      gameState.apply(TurnWildChildCommand(playerIndex));
    }

    return false;
  }
}

@MappableClass(discriminatorValue: 'turnWildChild')
class TurnWildChildCommand
    with TurnWildChildCommandMappable
    implements GameCommand {
  final int playerIndex;

  TurnWildChildCommand(this.playerIndex);

  bool? _previousTurned;

  @override
  void apply(GameData gameData) {
    final player = gameData.players[playerIndex];
    final role = player.role as WildChildRole;
    _previousTurned = role.turned;
    role.turned = true;
  }

  @override
  bool get canBeUndone => _previousTurned != null;

  @override
  void undo(GameData gameData) {
    final player = gameData.players[playerIndex];
    final role = player.role as WildChildRole;
    role.turned = _previousTurned!;

    _previousTurned = null;
  }
}
