import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/state/game_phase.dart';
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
  bool showDeathAnnouncement = false;

  @override
  Widget build(BuildContext context) {
    if (setupResult != null) {
      return ChangeNotifierProvider(
        create: (context) => GameState(
          players: setupResult!.players,
          roleCounts: setupResult!.selectedRoles,
        ),
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            final answer = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => LeaveGameDialog(),
            );

            if (answer == true && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Consumer<GameState>(
            builder: (context, gameState, child) {
              void onPhaseComplete() {
                if (gameState.pendingDeathAnnouncements && !gameState.isNight) {
                  showDeathAnnouncement = true;
                } else {
                  showDeathAnnouncement = false;
                  if (gameState.phase != GamePhase.gameOver) {
                    gameState.transitionToNextPhase();
                  }
                }
              }

              return Theme(
                data: gameState.isNight ? ThemeData.dark() : ThemeData.light(),
                child: showDeathAnnouncement
                    ? DeathsScreen(onPhaseComplete: onPhaseComplete)
                    : GamePhaseScreen(
                        phase: gameState.phase,
                        onPhaseComplete: onPhaseComplete,
                      ),
              );
            },
          ),
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
