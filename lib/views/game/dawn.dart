import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/util/gradient.dart';

class DawnScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;

  const DawnScreen({super.key, required this.onPhaseComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('The village wakes as dawn breaks...'),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomCenter,
            radius: 2,
            colors: [Colors.orange.shade300, Colors.transparent],
            stops: const [0.0, 0.7],
            transform: ScaleGradient(scaleX: 1.25, scaleY: 0.75),
          ),
        ),
        height: double.infinity,
        child: Consumer<GameState>(
          builder: (context, gameState, child) {
            final previousCycleDeaths = gameState.previousCycleDeaths;
            if (previousCycleDeaths.isEmpty) {
              return Center(
                child: Text(
                  'No one died last night.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              );
            }

            return ListView.builder(
              itemBuilder: (context, index) {
                final playerIndex = previousCycleDeaths.keys.elementAt(index);
                final player = gameState.players[playerIndex];
                final deathReason = previousCycleDeaths[playerIndex];
                if (deathReason == null) {
                  return const SizedBox.shrink();
                }
                return ListTile(
                  title: Text(
                    'Player ${player.name} has died.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  subtitle: Text(
                    '- ${deathReason.name(context)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              },
              itemCount: previousCycleDeaths.length,
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
          onPressed: onPhaseComplete,
          label: const Text('Continue'),
          icon: const Icon(Icons.arrow_forward),
        ),
      ),
    );
  }
}
