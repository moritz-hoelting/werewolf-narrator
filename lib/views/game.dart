import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_data.dart'
    show TransitionToNextPhaseCommand, GamePhase;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/themes.dart';
import 'package:werewolf_narrator/views/game/deaths_screen.dart';
import 'package:werewolf_narrator/views/game/game_setup.dart';
import 'package:werewolf_narrator/views/game/phase_manager_screen.dart';

class GameView extends StatefulWidget {
  const GameView({super.key});

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  GameSetupResult? setupResult;

  @override
  Widget build(BuildContext context) {
    if (setupResult != null) {
      return ChangeNotifierProvider(
        create: (context) => GameState(
          playerNames: setupResult!.players,
          roleConfigurations: setupResult!.selectedRoles,
        ),
        child: Consumer<GameState>(
          builder: (context, gameState, child) {
            final showDeathsScreen =
                gameState.pendingDeathAnnouncements &&
                (!gameState.isNight || gameState.phase == GamePhase.dusk) &&
                !gameState.pendingDeathAnnouncementsFromNight;

            return Theme(
              data: gameState.isNight && !showDeathsScreen
                  ? Themes.nighttimeTheme(context)
                  : Themes.daytimeTheme(context),
              child: Builder(
                builder: (context) => PopScope(
                  canPop: gameState.phase == GamePhase.gameOver,
                  onPopInvokedWithResult: (didPop, result) async {
                    if (didPop) return;

                    final answer = await showDialog<bool>(
                      useRootNavigator: false,
                      context: context,
                      builder: (dialogContext) => LeaveGameDialog(),
                    );

                    if (answer == true && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: showDeathsScreen
                      ? DeathsScreen(key: UniqueKey())
                      : GamePhaseScreen(
                          phase: gameState.phase,
                          onPhaseComplete: () {
                            if (gameState.phase != GamePhase.gameOver) {
                              gameState.finishBatch(
                                TransitionToNextPhaseCommand(),
                              );
                            }
                          },
                        ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      return GameSetupView(
        onFinished: (result) {
          setState(() {
            setupResult = result;
          });
        },
      );
    }
  }
}

class LeaveGameDialog extends StatelessWidget {
  const LeaveGameDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AlertDialog(
      icon: const Icon(Icons.exit_to_app),
      title: Text(localizations.alert_leaveGame_title),
      content: Text(localizations.alert_leaveGame_message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}
