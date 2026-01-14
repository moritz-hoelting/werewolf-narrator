import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      disabledForegroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
    );

    return Consumer<GameState>(
      builder: (context, gameState, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Select action for ${Role.witch.name(context)}'),
            automaticallyImplyLeading: false,
          ),
          body: gameState.witchHasHealPotion || gameState.witchHasKillPotion
              ? Column(
                  children: [
                    TextButton.icon(
                      style: modeButtonStyle,
                      onPressed: _killModeActive && gameState.witchHasHealPotion
                          ? () {
                              setState(() {
                                _killModeActive = false;
                              });
                            }
                          : null,
                      label: const Text('Heal Player'),
                      icon: const Icon(Icons.healing),
                    ),
                    TextButton.icon(
                      style: modeButtonStyle,
                      onPressed:
                          !_killModeActive && gameState.witchHasKillPotion
                          ? () {
                              setState(() {
                                _killModeActive = true;
                              });
                            }
                          : null,
                      label: const Text('Kill Player'),
                      icon: const Icon(Icons.close),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: gameState.playerCount,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(gameState.players[index].name),
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
                          );
                        },
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Text(
                    'No potions left to use.',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
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
              label: const Text('Continue'),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        );
      },
    );
  }

  bool playerTapEnabled(int index, GameState gameState) =>
      gameState.playerAliveOrKilledThisCycle(index) &&
      (_killModeActive
          ? (gameState.players[index].role != Role.witch &&
                gameState.playerAliveOrKilledThisCycle(index))
          : (gameState.currentCycleDeaths.containsKey(index) &&
                gameState.currentCycleDeaths[index] == DeathReason.werewolf));
}
