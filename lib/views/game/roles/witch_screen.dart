import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/death_information.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/state/game.dart';

class WitchScreen extends StatefulWidget {
  final VoidCallback onPhaseComplete;

  const WitchScreen({super.key, required this.onPhaseComplete});

  @override
  State<WitchScreen> createState() => _WitchScreenState();
}

class _WitchScreenState extends State<WitchScreen> {
  int? _selectedKillPlayer;
  int? _selectedHealPlayer;

  late bool _killModeActive;

  @override
  void initState() {
    super.initState();
    _killModeActive = !Provider.of<GameState>(
      context,
      listen: false,
    ).witchHasHealPotion;
  }

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
          body: gameState.witchHasHealPotion || gameState.witchHasKillPotion
              ? Column(
                  children: [
                    TextButton.icon(
                      style: !_killModeActive
                          ? selectedModeButtonStyle
                          : modeButtonStyle,
                      onPressed: _killModeActive && gameState.witchHasHealPotion
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
                      onPressed:
                          !_killModeActive && gameState.witchHasKillPotion
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
                gameState.witchUseUpPotion(
                  heal: _selectedHealPlayer != null,
                  kill: _selectedKillPlayer != null,
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
            ? (gameState.players[index].role != Role.witch &&
                  gameState.playerAliveOrKilledThisCycle(index) &&
                  !killedByWerewolves)
            : (killedByWerewolves));
  }
}
