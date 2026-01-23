part of 'role.dart';

class WitchRole extends Role {
  WitchRole._();
  static final RoleType type = RoleType<WitchRole>();
  @override
  RoleType get objectType => type;

  static final Role instance = WitchRole._();

  static void registerRole() {
    RoleManager.registerRole<WitchRole>(
      RegisterRoleInformation(WitchRole._, instance),
    );
  }

  int healPotions = 1;
  int killPotions = 1;

  @override
  bool get isUnique => true;
  @override
  TeamType get initialTeam => VillageTeam.type;

  @override
  String name(BuildContext context) {
    return AppLocalizations.of(context)!.role_witch_name;
  }

  @override
  String description(BuildContext context) {
    return AppLocalizations.of(context)!.role_witch_description;
  }

  @override
  String checkRoleInstruction(BuildContext context, int count) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.screen_checkRoles_instruction_witch(count);
  }

  @override
  bool hasNightScreen(GameState gameState) => true;
  @override
  WidgetBuilder? nightActionScreen(VoidCallback onComplete) =>
      (context) => WitchScreen(
        onPhaseComplete: onComplete,
        healPotions: healPotions,
        killPotions: killPotions,
        useUpPotions: ({heal = 0, kill = 0}) {
          healPotions -= heal;
          killPotions -= kill;
          if (heal > 0 || kill > 0) {
            Provider.of<GameState>(context, listen: false).notifyUpdate();
          }
        },
      );
}

class WitchScreen extends StatefulWidget {
  final VoidCallback onPhaseComplete;
  final int healPotions;
  final int killPotions;

  final void Function({int heal, int kill}) useUpPotions;

  const WitchScreen({
    super.key,
    required this.onPhaseComplete,
    required this.healPotions,
    required this.killPotions,
    required this.useUpPotions,
  });

  @override
  State<WitchScreen> createState() => _WitchScreenState();
}

class _WitchScreenState extends State<WitchScreen> {
  int? _selectedKillPlayer;
  int? _selectedHealPlayer;

  late bool _killModeActive = widget.healPotions == 0;

  @override
  Widget build(BuildContext context) {
    final modeButtonStyle = TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onSurface,
    );
    final selectedModeButtonStyle = TextButton.styleFrom(
      disabledForegroundColor: Theme.of(context).colorScheme.primary,
    );

    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final localizations = AppLocalizations.of(context)!;

        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.role_witch_name),
            automaticallyImplyLeading: false,
          ),
          body: widget.healPotions > 0 || widget.killPotions > 0
              ? Column(
                  children: [
                    TextButton.icon(
                      style: !_killModeActive
                          ? selectedModeButtonStyle
                          : modeButtonStyle,
                      onPressed: _killModeActive && widget.healPotions > 0
                          ? () {
                              setState(() {
                                _killModeActive = false;
                              });
                            }
                          : null,
                      label: Text(
                        localizations.screen_roleAction_instruction_witch_heal,
                      ),
                      icon: const Icon(Icons.healing),
                    ),
                    TextButton.icon(
                      style: _killModeActive
                          ? selectedModeButtonStyle
                          : modeButtonStyle,
                      onPressed: !_killModeActive && widget.killPotions > 0
                          ? () {
                              setState(() {
                                _killModeActive = true;
                              });
                            }
                          : null,
                      label: Text(
                        localizations.screen_roleAction_instruction_witch_kill,
                      ),
                      icon: const Icon(Icons.science),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        localizations.screen_roleAction_instruction_witch,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: gameState.playerCount,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(gameState.players[index].name),
                            trailing: _selectedHealPlayer == index
                                ? const Icon(Icons.healing)
                                : (_selectedKillPlayer == index
                                      ? const Icon(Icons.science)
                                      : null),
                            onTap: playerTapEnabled(index, gameState)
                                ? () {
                                    setState(() {
                                      if (_killModeActive) {
                                        if (_selectedKillPlayer == index) {
                                          _selectedKillPlayer = null;
                                        } else {
                                          _selectedKillPlayer = index;
                                        }
                                      } else {
                                        if (_selectedHealPlayer == index) {
                                          _selectedHealPlayer = null;
                                        } else {
                                          _selectedHealPlayer = index;
                                        }
                                      }
                                    });
                                  }
                                : null,
                            selected:
                                (_selectedKillPlayer == index &&
                                    _killModeActive) ||
                                (_selectedHealPlayer == index &&
                                    !_killModeActive),
                            enabled: playerTapEnabled(index, gameState),
                            selectedTileColor: _killModeActive
                                ? Colors.red.withAlpha(50)
                                : Colors.green.withAlpha(50),
                            tileColor: _killModeActive
                                ? (_selectedHealPlayer == index
                                      ? Colors.green.withAlpha(30)
                                      : null)
                                : (_selectedKillPlayer == index
                                      ? Colors.red.withAlpha(30)
                                      : null),
                          );
                        },
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    localizations
                        .screen_roleAction_instruction_witch_noPotionsLeft,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed: () {
                if (_selectedHealPlayer != null) {
                  gameState.witchHealPlayer(_selectedHealPlayer!);
                }
                if (_selectedKillPlayer != null) {
                  gameState.markPlayerDead(
                    _selectedKillPlayer!,
                    DeathReason.witch,
                  );
                }
                widget.useUpPotions(
                  heal: _selectedHealPlayer != null ? 1 : 0,
                  kill: _selectedKillPlayer != null ? 1 : 0,
                );
                widget.onPhaseComplete();
              },
              label: Text(localizations.button_continueLabel),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        );
      },
    );
  }

  bool playerTapEnabled(int index, GameState gameState) {
    final killedByWerewolves =
        gameState.currentCycleDeaths.containsKey(index) &&
        gameState.currentCycleDeaths[index] == DeathReason.werewolf;
    return gameState.playerAliveOrKilledThisCycle(index) &&
        (_killModeActive
            ? (gameState.players[index].role?.objectType != WitchRole.type &&
                  gameState.playerAliveOrKilledThisCycle(index) &&
                  !killedByWerewolves)
            : (killedByWerewolves));
  }
}
