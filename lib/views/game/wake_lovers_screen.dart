import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/state/game.dart';

class WakeLoversScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;

  const WakeLoversScreen({super.key, required this.onPhaseComplete});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Wake Lovers'),
            automaticallyImplyLeading: false,
          ),
          body: gameState.lovers != null
              ? Text(
                  '${gameState.players[gameState.lovers!.$1].name} and ${gameState.players[gameState.lovers!.$2].name}, wake up and look at each other.',
                  style: Theme.of(context).textTheme.headlineLarge,
                )
              : const SizedBox.shrink(),
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
      },
    );
  }
}
