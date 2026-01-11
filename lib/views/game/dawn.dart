import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/state/game.dart';

class DawnScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;

  const DawnScreen({super.key, required this.onPhaseComplete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('The village wakes as dawn breaks...'),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.surface, Colors.orange.shade300],
            stops: const [0.65, 1.0],
          ),
        ),
        height: double.infinity,
        child: Consumer<GameState>(
          builder: (context, gameState, child) {
            if (gameState.nightDeaths.isEmpty) {
              return Center(
                child: Text(
                  'No one died last night.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              );
            }

            return ListView.builder(
              itemBuilder: (context, index) {
                final playerIndex = gameState.nightDeaths.keys.elementAt(index);
                final player = gameState.players[playerIndex];
                final deathReasons = gameState.nightDeaths[playerIndex];
                if (deathReasons == null || deathReasons.isEmpty) {
                  return const SizedBox.shrink();
                }
                return ListTile(
                  title: Text(
                    'Player ${player.name} has died.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: deathReasons
                        .map(
                          (reason) => Text(
                            '- ${reason.name(context)}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                        .toList(),
                  ),
                );
              },
              itemCount: gameState.nightDeaths.length,
              shrinkWrap: true,
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(60),
          ),
          onPressed: () {
            Provider.of<GameState>(context, listen: false).clearNightDeaths();
            onPhaseComplete();
          },
          label: const Text('Continue'),
          icon: const Icon(Icons.arrow_forward),
        ),
      ),
    );
  }
}
