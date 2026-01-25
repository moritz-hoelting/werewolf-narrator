import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/util/gradient.dart';
import 'package:werewolf_narrator/views/game/death_actions_screen.dart';

class DeathsScreen extends StatelessWidget {
  final VoidCallback onPhaseComplete;
  final Widget? title;
  final Color? beamColor;

  const DeathsScreen({
    super.key,
    required this.onPhaseComplete,
    this.title,
    this.beamColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        if (!gameState.pendingDeathAnnouncements &&
            gameState.pendingDeathActions) {
          return DeathActionsScreen(onPhaseComplete: onPhaseComplete);
        }

        final localizations = AppLocalizations.of(context)!;
        final unannouncedDeaths = gameState.unannouncedDeaths;

        return Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: title ?? Text(localizations.screen_deaths_title),
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomCenter,
                radius: 2,
                colors: [beamColor ?? Colors.grey.shade700, Colors.transparent],
                stops: const [0.0, 0.7],
                transform: ScaleGradient(scaleX: 1.25, scaleY: 0.75),
              ),
            ),
            height: double.infinity,
            child: unannouncedDeaths.isEmpty
                ? Center(
                    child: Text(
                      localizations.screen_deaths_noDeaths,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  )
                : ListView.builder(
                    itemBuilder: (context, index) {
                      final playerIndex = unannouncedDeaths.keys.elementAt(
                        index,
                      );
                      final player = gameState.players[playerIndex];
                      final deathInformation = unannouncedDeaths[playerIndex]!;
                      return ListTile(
                        title: Text(
                          localizations.screen_deaths_playerHasDied(
                            player.name,
                          ),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        subtitle: Text(
                          '${player.role?.name(context) ?? localizations.role_unknown_name} - ${deathInformation.reason.deathReasonDescription(context)}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    },
                    itemCount: unannouncedDeaths.length,
                    shrinkWrap: true,
                  ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed: () {
                GameState gameState = Provider.of<GameState>(
                  context,
                  listen: false,
                );
                gameState.markDeathsAnnounced();

                if (!gameState.pendingDeathActions) {
                  onPhaseComplete();
                }
              },
              label: Text(localizations.button_continueLabel),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        );
      },
    );
  }
}
