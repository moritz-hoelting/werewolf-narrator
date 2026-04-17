import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_data.dart'
    show ProcessPendingDeathsCommand;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/util/gradient.dart';
import 'package:werewolf_narrator/views/game/death_actions_screen.dart';
import 'package:werewolf_narrator/widgets/game/app_bar.dart';

class DeathsScreen extends StatelessWidget {
  final VoidCallback? onPhaseComplete;
  final Widget? title;
  final Color? beamColor;

  const DeathsScreen({
    super.key,
    this.onPhaseComplete,
    this.title,
    this.beamColor,
  });

  @override
  Widget build(BuildContext context) => Consumer<GameState>(
    builder: (context, gameState, child) {
      if (!gameState.pendingDeathAnnouncements &&
          gameState.firstPlayerWithPendingDeathAction != null) {
        return DeathActionsScreen(onPhaseComplete: onPhaseComplete ?? () {});
      }

      final localizations = AppLocalizations.of(context);
      final pendingDeaths = gameState.pendingDeaths;

      return Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: GameAppBar(
          title: title ?? Text(localizations.screen_deaths_title),
          backgroundColor: Colors.transparent,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.bottomCenter,
              radius: 2,
              colors: [beamColor ?? Colors.grey.shade700, Colors.transparent],
              stops: const [0.0, 0.7],
              transform: const ScaleGradient(scaleX: 1.25, scaleY: 0.75),
            ),
          ),
          height: double.infinity,
          child: pendingDeaths.isEmpty
              ? Center(
                  child: Text(
                    localizations.screen_deaths_noDeaths,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                )
              : ListView.builder(
                  itemBuilder: (context, index) {
                    final playerIndex = pendingDeaths.keys.elementAt(index);
                    final player = gameState.players[playerIndex];
                    final deathInformation = pendingDeaths[playerIndex]!;
                    return ListTile(
                      title: Text(
                        localizations.screen_deaths_playerHasDied(
                          playerName: player.name,
                        ),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      subtitle: Text(
                        '${player.role?.name(context) ?? localizations.role_unknown_name} - ${deathInformation.firstOrNull?.reason.deathReasonDescription(context)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  },
                  itemCount: pendingDeaths.length,
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
              final gameState = Provider.of<GameState>(context, listen: false);
              gameState.apply(ProcessPendingDeathsCommand());

              final firstPlayerWithPendingDeathAction =
                  gameState.firstPlayerWithPendingDeathAction;

              if (firstPlayerWithPendingDeathAction == null &&
                  onPhaseComplete != null) {
                onPhaseComplete!();
              } else {
                gameState.finishBatch();
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
