import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/state/game.dart';

class WakeLoversScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;

  const WakeLoversScreen({super.key, required this.onPhaseComplete});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        assert(
          gameState.lovers != null,
          'Lovers should be set when waking them up.',
        );

        final localizations = AppLocalizations.of(context)!;
        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.screen_wakeLovers_title),
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16.0,
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 160),
                Text(
                  localizations.screen_wakeLovers_instructions(
                    gameState.players[gameState.lovers!.$1].name,
                    gameState.players[gameState.lovers!.$2].name,
                  ),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed: onPhaseComplete,
              label: Text(localizations.button_continueLabel),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        );
      },
    );
  }
}
