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
  bool setupFinished = false;

  @override
  Widget build(BuildContext context) {
    if (setupFinished) {
      return ChangeNotifierProvider(
        create: (context) => GameState(),
        child: Scaffold(
          appBar: AppBar(title: Text('Game')),
          body: const Placeholder(),
        ),
      );
    } else {
      return GameSetupView(onFinished: () {
        setState(() {
          setupFinished = true;
        });
      });
    }
  }
}
