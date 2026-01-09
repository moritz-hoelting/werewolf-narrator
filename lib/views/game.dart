import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/views/game/game_setup.dart';

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
              child: Scaffold(
                appBar: AppBar(title: Text('Game')),
                body: const Placeholder(),
              ),
            );
          },
        ),
      );
    } else {
      return GameSetupView(
        onFinished: (result) {
          print('Players: ${result.players}');
          print('Selected Roles: ${result.selectedRoles}');
          setState(() {
            setupResult = result;
          });
        },
      );
    }
  }
}
