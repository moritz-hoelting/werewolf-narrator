import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_annotations/register_role.dart' show RegisterRole;
import 'package:werewolf_narrator/game/commands/remove_unassigned_roles.dart';
import 'package:werewolf_narrator/game/commands/set_players_role.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/model/configuration_options.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/role/village/villager.dart'
    show VillagerRole;
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/views/game/binary_selection_screen.dart';

part 'thief.mapper.dart';

@RegisterRole()
class ThiefRole extends Role {
  ThiefRole._({required RoleConfiguration config, required super.playerIndex});
  static final RoleType type = RoleType.of<ThiefRole>();
  @override
  RoleType get roleType => type;

  static void registerRole() {
    RoleManager.registerRole<ThiefRole>(
      type,
      RegisterRoleInformation(
        constructor: ThiefRole._,
        name: (context) => AppLocalizations.of(context).role_thief_name,
        description: (context) =>
            AppLocalizations.of(context).role_thief_description,
        initialTeam: VillageTeam.type,
        checkRoleInstruction: (context, count) => AppLocalizations.of(
          context,
        ).role_thief_checkInstruction(count: count),
        validRoleCounts: const [1],
        addedRoleCardAmount: 3,
        initialize: initialize,
        roleCountAdjuster: (roleCounts, playerCount) {
          final thiefRoleType = ThiefRole.type;
          final villagerRoleType = VillagerRole.type;

          if (roleCounts[thiefRoleType] != null &&
              roleCounts[thiefRoleType]!.count > 0) {
            roleCounts[villagerRoleType] = (
              count:
                  (roleCounts[villagerRoleType]?.count ?? 0) +
                  (2 * roleCounts[thiefRoleType]!.count),
              config: (roleCounts[villagerRoleType]?.config ?? {}),
            );
          }
        },
        chooseRolesInformation: const ChooseRolesInformation(
          category: ChooseRolesCategory.village,
        ),
      ),
    );
  }

  static void initialize(GameState gameState) {
    gameState.apply(InitializeThiefCommand());
  }

  @override
  void onAssign(GameState gameState) {
    super.onAssign(gameState);

    gameState.apply(RegisterThiefNightActionCommand(playerIndex));
  }
}

class ThiefScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;
  final int playerIndex;

  const ThiefScreen({
    required this.onPhaseComplete,
    required this.playerIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Consumer<GameState>(
    builder: (context, gameState, child) {
      final localizations = AppLocalizations.of(context);

      final missingRoles = gameState.unassignedRoles;

      assert(
        missingRoles.length ==
            2 * gameState.roleConfigurations[ThiefRole.type]!.count,
        'Number of missing roles must match twice the number of Thief roles assigned',
      );

      final (roleA, roleB) = (missingRoles[0], missingRoles[1]);

      return BinarySelectionScreen(
        key: UniqueKey(),
        appBarTitle: Text(localizations.role_thief_name),
        instruction: Text(
          localizations.role_thief_nightAction_instruction,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        firstOption: Text(roleA.information.name(context)),
        secondOption: Text(roleB.information.name(context)),
        onComplete: (selectedFirst) => submit(
          gameState,
          selectedFirst != null ? (selectedFirst ? roleA : roleB) : null,
        ),
        allowSelectNone:
            roleA.information.initialTeam != WerewolvesTeam.type ||
            roleB.information.initialTeam != WerewolvesTeam.type,
      );
    },
  );

  void submit(GameState gameState, RoleType? selectedRole) {
    if (selectedRole != null) {
      gameState.apply(SetPlayersRoleCommand(selectedRole, ISet({playerIndex})));
    }
    gameState.apply(RemoveUnassignedRolesCommand());
    onPhaseComplete();
  }
}

@MappableClass(discriminatorValue: 'initializeThief')
class InitializeThiefCommand
    with InitializeThiefCommandMappable
    implements GameCommand {
  @override
  void apply(GameData gameData) {
    gameData.remainingRoleHooks
        .putIfAbsent(ThiefRole.type, () => [])
        .add(thiefRoleHook);
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.remainingRoleHooks[ThiefRole.type]?.remove(thiefRoleHook);
  }

  void thiefRoleHook(GameState gameState, int remainingCount) {
    gameState.apply(RemoveUnassignedRolesCommand());
  }
}

@MappableClass(discriminatorValue: 'registerThiefNightAction')
class RegisterThiefNightActionCommand
    with RegisterThiefNightActionCommandMappable
    implements GameCommand {
  const RegisterThiefNightActionCommand(this.playerIndex);

  final int playerIndex;

  @override
  void apply(GameData gameData) {
    gameData.nightActionManager.registerAction(
      ThiefRole.type,
      (gameState, onComplete) =>
          (context) => ThiefScreen(
            playerIndex: playerIndex,
            onPhaseComplete: onComplete,
          ),
      conditioned: (gameState) =>
          gameState.dayCounter == 0 && gameState.players[playerIndex].isAlive,
      beforeAll: true,
      players: {playerIndex},
    );
  }

  @override
  bool get canBeUndone => true;

  @override
  void undo(GameData gameData) {
    gameData.nightActionManager.unregisterAction(ThiefRole.type);
  }
}
