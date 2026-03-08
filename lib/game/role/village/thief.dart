import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/role/role.dart';
import 'package:werewolf_narrator/game/role/village/villager.dart'
    show VillagerRole;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/game/team/village.dart' show VillageTeam;
import 'package:werewolf_narrator/game/team/werewolves.dart'
    show WerewolvesTeam;
import 'package:werewolf_narrator/widgets/bottom_continue_button.dart';

class ThiefRole extends Role {
  ThiefRole._();
  static final RoleType type = RoleType<ThiefRole>();
  @override
  RoleType get objectType => type;

  static void registerRole() {
    RoleManager.registerRole<ThiefRole>(
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
              roleCounts[thiefRoleType]! > 0) {
            roleCounts[villagerRoleType] =
                (roleCounts[villagerRoleType] ?? 0) +
                (2 * roleCounts[thiefRoleType]!);
          }
        },
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

class ThiefScreen extends StatefulWidget {
  final VoidCallback onPhaseComplete;

  const ThiefScreen({super.key, required this.onPhaseComplete});

  @override
  State<ThiefScreen> createState() => _ThiefScreenState();
}

class _ThiefScreenState extends State<ThiefScreen> {
  _ThiefSelectedRole _selected = _ThiefSelectedRole.none;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final localizations = AppLocalizations.of(context);

        final missingRoles = gameState.unassignedRoles;

        assert(
          missingRoles.length == 2 * gameState.roleCounts[ThiefRole.type]!,
          'Number of missing roles must match twice the number of Thief roles assigned',
        );

        final (roleA, roleB) = (missingRoles[0], missingRoles[1]);

        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.role_thief_name),
            automaticallyImplyLeading: false,
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  localizations.role_thief_nightAction_instruction,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (_selected == _ThiefSelectedRole.roleA) {
                          _selected = _ThiefSelectedRole.none;
                        } else {
                          _selected = _ThiefSelectedRole.roleA;
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 150),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      backgroundColor: _selected == _ThiefSelectedRole.roleA
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.5)
                          : null,
                      elevation: 4,
                    ),
                    child: Text(roleA.information.name(context)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (_selected == _ThiefSelectedRole.roleB) {
                          _selected = _ThiefSelectedRole.none;
                        } else {
                          _selected = _ThiefSelectedRole.roleB;
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 150),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      backgroundColor: _selected == _ThiefSelectedRole.roleB
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.5)
                          : null,
                      elevation: 4,
                    ),
                    child: Text(roleB.information.name(context)),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: BottomContinueButton(
            onPressed:
                _selected == _ThiefSelectedRole.none &&
                    roleA.information.initialTeam == WerewolvesTeam.type &&
                    roleB.information.initialTeam == WerewolvesTeam.type
                ? null
                : () {
                    submit(gameState, roleA, roleB);
                  },
          ),
        );
      },
    );
  }

  void submit(GameState gameState, RoleType roleA, RoleType roleB) {
    if (_selected != _ThiefSelectedRole.none) {
      final selectedRole = _selected == _ThiefSelectedRole.roleA
          ? roleA
          : roleB;
      gameState.setPlayersRole(
        selectedRole,
        gameState.players.indexed
            .where((player) => player.$2.role is ThiefRole)
            .map((player) => player.$1)
            .toList(),
      );
    }
    gameState.removeUnassignedRoles();
    widget.onPhaseComplete();
  }
}

enum _ThiefSelectedRole { none, roleA, roleB }
