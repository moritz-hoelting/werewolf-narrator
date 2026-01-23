part of 'role.dart';

class ThiefRole extends Role {
  const ThiefRole._();
  static final RoleType type = RoleType<ThiefRole>();
  @override
  RoleType get objectType => type;

  static const Role instance = ThiefRole._();

  static void registerRole() {
    RoleManager.registerRole<ThiefRole>(
      RegisterRoleInformation(ThiefRole._, instance, initialize: initialize),
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
    );
  }

  @override
  bool get isUnique => true;
  @override
  TeamType get initialTeam => VillageTeam.type;

  @override
  String name(BuildContext context) {
    return AppLocalizations.of(context)!.role_thief_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context)!.role_thief_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.screen_checkRoles_instruction_thief(count);
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
        final localizations = AppLocalizations.of(context)!;

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
                  localizations.screen_roleAction_instruction_thief,
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
                    child: Text(roleA.name(context)),
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
                    child: Text(roleB.name(context)),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed:
                  _selected == _ThiefSelectedRole.none &&
                      roleA.instance.team(gameState) == WerewolvesTeam.type &&
                      roleB.instance.team(gameState) == WerewolvesTeam.type
                  ? null
                  : () {
                      submit(gameState, roleA, roleB);
                    },
              label: Text(localizations.button_continueLabel),
              icon: const Icon(Icons.arrow_forward),
            ),
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
