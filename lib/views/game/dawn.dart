import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/state/game.dart';

class DawnScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;

  const DawnScreen({super.key, required this.onPhaseComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The village wakes as dawn breaks...'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<GameState>(
        builder: (context, gameState, child) => ListView.builder(
          itemBuilder: (context, index) {
            final player = gameState.players[index];
            final deathReasons = gameState.nightDeaths[index];
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
          itemCount: gameState.playerCount,
          shrinkWrap: true,
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
