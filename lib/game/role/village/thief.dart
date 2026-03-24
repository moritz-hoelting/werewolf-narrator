import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/model/role_config.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/role/village/villager.dart'
    show VillagerRole;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/views/game/binary_selection_screen.dart';

class ThiefRole extends Role {
  ThiefRole._(RoleConfiguration config);
  static final RoleType<ThiefRole> type = RoleType<ThiefRole>();
  @override
  RoleType<ThiefRole> get objectType => type;

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
        chooseRolesInformation: ChooseRolesInformation(
          category: ChooseRolesCategory.village,
        ),
      ),
    );
  }

  static void initialize(GameState gameState) {
    gameState.remainingRoleHooks.putIfAbsent(ThiefRole.type, () => []).add((
      gameState,
      remainingCount,
    ) {
      gameState.removeUnassignedRoles();
    });
  }

  @override
  void onAssign(GameState gameState, int playerIndex) {
    super.onAssign(gameState, playerIndex);

    gameState.nightActionManager.registerAction(
      ThiefRole.type,
      (gameState, onComplete) =>
          (context) => ThiefScreen(onPhaseComplete: onComplete),
      conditioned: (gameState) =>
          gameState.dayCounter == 0 &&
          gameState.playerAliveUntilDawn(playerIndex),
      beforeAll: true,
      players: {playerIndex},
    );
  }
}

class ThiefScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;

  const ThiefScreen({super.key, required this.onPhaseComplete});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
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
  }

  void submit(GameState gameState, RoleType? selectedRole) {
    if (selectedRole != null) {
      gameState.setPlayersRole(
        selectedRole,
        gameState.players.indexed
            .where((player) => player.$2.role is ThiefRole)
            .map((player) => player.$1)
            .toList(),
      );
    }
    gameState.removeUnassignedRoles();
    onPhaseComplete();
  }
}
