import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_command.dart';
import 'package:werewolf_narrator/game/game_data.dart'
    show GameData, GameOverCommand;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/util/gradient.dart';
import 'package:werewolf_narrator/views/game/death_actions_screen.dart';
import 'package:werewolf_narrator/widgets/game/app_bar.dart';

part 'deaths_screen.mapper.dart';

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
      final unannouncedDeaths = gameState.unannouncedDeaths;

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
          child: unannouncedDeaths.isEmpty
              ? Center(
                  child: Text(
                    localizations.screen_deaths_noDeaths,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                )
              : ListView.builder(
                  itemBuilder: (context, index) {
                    final playerIndex = unannouncedDeaths.keys.elementAt(index);
                    final player = gameState.players[playerIndex];
                    final deathInformation = unannouncedDeaths[playerIndex]!;
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
              final gameState = Provider.of<GameState>(context, listen: false);
              gameState.apply(MarkDeathsAnnouncedCommand());

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

@MappableClass(discriminatorValue: 'markDeathsAnnounced')
class MarkDeathsAnnouncedCommand
    with MarkDeathsAnnouncedCommandMappable
    implements GameCommand {
  ISet<int>? _previouslyUnannouncedDeaths;

  @override
  void apply(GameData gameData) {
    _previouslyUnannouncedDeaths = gameData.unannouncedDeaths.keys.toISet();
    for (final playerIndex in gameData.unannouncedDeaths.keys) {
      gameData.players[playerIndex].deathAnnounced = true;
    }
    if (gameData.checkWinConditions() != null) {
      gameData.state.apply(GameOverCommand());
    }
  }

  @override
  bool get canBeUndone => _previouslyUnannouncedDeaths != null;

  @override
  void undo(GameData gameData) {
    for (final playerIndex in _previouslyUnannouncedDeaths!) {
      gameData.players[playerIndex].deathAnnounced = false;
    }
    _previouslyUnannouncedDeaths = null;
  }
}
