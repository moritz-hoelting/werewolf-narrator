import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/views/game/create_players.dart';
import 'package:werewolf_narrator/views/game/select_roles.dart';

class GameSetupView extends StatefulWidget {
  final void Function(GameSetupResult) onFinished;

  const GameSetupView({super.key, required this.onFinished});

  @override
  State<GameSetupView> createState() => _GameSetupViewState();
}

class _GameSetupViewState extends State<GameSetupView> {
  GameSetupStep step = GameSetupStep.createPlayers;

  List<String> players = kDebugMode
      ? List.generate(8, (i) => 'Player ${i + 1}')
      : [];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: step == GameSetupStep.createPlayers,
      onPopInvokedWithResult: (didPop, result) {
        switch (step) {
          case GameSetupStep.createPlayers:
            break;
          case GameSetupStep.selectRoles:
            setState(() {
              step = GameSetupStep.createPlayers;
            });
            break;
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(step.title(context))),
        body: switch (step) {
          GameSetupStep.createPlayers => CreatePlayersScreen(
            onSubmit: submitCreatePlayers,
            initialPlayers: players,
          ),
          GameSetupStep.selectRoles => SelectRolesView(
            playerCount: players.length,
            onSubmit: (selectedRoles) => widget.onFinished(
              GameSetupResult(players: players, selectedRoles: selectedRoles),
            ),
          ),
        },
      ),
    );
  }

  void submitCreatePlayers(List<String> createdPlayers) {
    setState(() {
      step = GameSetupStep.selectRoles;
      players = createdPlayers;
    });
  }
}

enum GameSetupStep {
  createPlayers,
  selectRoles;

  String title(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    switch (this) {
      case GameSetupStep.createPlayers:
        return localizations.screen_gameSetup_createPlayers_title;
      case GameSetupStep.selectRoles:
        return localizations.screen_gameSetup_selectRoles_title;
    }
  }
}

class GameSetupResult {
  final List<String> players;
  final Map<RoleType, int> selectedRoles;

  GameSetupResult({required this.players, required this.selectedRoles});
}
