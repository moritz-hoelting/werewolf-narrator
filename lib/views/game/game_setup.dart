import 'package:flutter/material.dart';
import 'package:werewolf_narrator/views/game/create_players.dart';
import 'package:werewolf_narrator/views/game/select_roles.dart';

class GameSetupView extends StatefulWidget {
  final VoidCallback onFinished;

  const GameSetupView({super.key, required this.onFinished});

  @override
  State<GameSetupView> createState() => _GameSetupViewState();
}

class _GameSetupViewState extends State<GameSetupView> {
  GameStep step = GameStep.createPlayers;
  List<String> players = [];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: step == GameStep.createPlayers,
      onPopInvokedWithResult: (didPop, result) {
        switch (step) {
          case GameStep.createPlayers:
            // Allow pop
            break;
          case GameStep.selectRoles:
            setState(() {
              step = GameStep.createPlayers;
            });
            break;
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(step.title)),
        body: switch (step) {
          GameStep.createPlayers => CreatePlayersScreen(
            onSubmit: submitCreatePlayers,
            initialPlayers: players,
          ),
          GameStep.selectRoles => SelectRolesView(
            playerCount: players.length,
            onSubmit: widget.onFinished,
          ),
        },
      ),
    );
  }

  void submitCreatePlayers(List<String> createdPlayers) {
    setState(() {
      step = GameStep.selectRoles;
      players = createdPlayers;
    });
  }
}

enum GameStep {
  createPlayers,
  selectRoles;

  String get title {
    switch (this) {
      case GameStep.createPlayers:
        return 'Create Players';
      case GameStep.selectRoles:
        return 'Select Roles';
    }
  }
}
