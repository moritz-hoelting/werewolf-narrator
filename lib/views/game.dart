import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/state/game.dart';
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
          players: setupResult!.players,
          roles: setupResult!.selectedRoles,
        ),
        child: Consumer<GameState>(
          builder: (context, gameState, child) {
            return Theme(
              data: gameState.isNight ? ThemeData.dark() : ThemeData.light(),
              child: GamePhaseScreen(
                phase: gameState.phase,
                onPhaseComplete: () {
                  if (gameState.phase != GamePhase.gameOver) {
                    gameState.transitionToNextPhase();
                  }
                },
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
