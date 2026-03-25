import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:werewolf_narrator/game/game_command.dart' show GameCommand;
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/model/death_information.dart'
    show DeathReason;
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
  WildChildRole._({
    required RoleConfiguration config,
    required super.playerIndex,
  });

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
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(RegisterWildChildNightActionCommand(playerIndex));
  }
}

class RegisterWildChildNightActionCommand implements GameCommand {
  const RegisterWildChildNightActionCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    gameData.nightActionManager.registerAction(
      WildChildRole.type,
      (gameState, onComplete) {
        return nightActionScreen(playerIndex, onComplete);
      },
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
    // TODO: implement undo
    throw UnimplementedError();
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

class WildChildSelectRoleModelCommand implements GameCommand {
  const WildChildSelectRoleModelCommand({
    required this.playerIndex,
    required this.roleModelIndex,
  });

  final int playerIndex;
  final int roleModelIndex;

  @override
  void apply(GameData gameData) {
    final player = gameData.players[playerIndex];
    final role = player.role as WildChildRole;

    role.roleModel = roleModelIndex;
    if (!gameData.players[roleModelIndex].isAlive) {
      role.turned = true;
    } else {
      gameData.deathHooks.add(deathHook);
    }
  }

  @override
  // TODO: implement canBeUndone
  bool get canBeUndone => false;

  @override
  void undo(GameData gameData) {
    // TODO: implement undo
    throw UnimplementedError();
  }

  bool deathHook(GameState gameState, int index, DeathReason reason) {
    if (index == roleModelIndex) {
      gameState.apply(TurnWildChildCommand(playerIndex));
    }

    return false;
  }
}

class TurnWildChildCommand implements GameCommand {
  const TurnWildChildCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    final player = gameData.players[playerIndex];
    final role = player.role as WildChildRole;
    role.turned = true;
  }

  @override
  bool get canBeUndone => false;

  @override
  void undo(GameData gameData) {
    throw UnimplementedError();
  }
}
