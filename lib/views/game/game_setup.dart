import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/database/database.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/role_config.dart'
    show RoleConfiguration;
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/util/developer_settings.dart';
import 'package:werewolf_narrator/views/game/choose_roles_screen.dart';
import 'package:werewolf_narrator/views/game/create_players.dart';

class GameSetupView extends StatefulWidget {
  final void Function(GameSetupResult) onFinished;

  const GameSetupView({required this.onFinished, super.key});

  @override
  State<GameSetupView> createState() => _GameSetupViewState();
}

class _GameSetupViewState extends State<GameSetupView> {
  GameSetupStep step = GameSetupStep.createPlayers;

  late List<String> players =
      Provider.of<DeveloperSettings>(context).fillPlayerNamesEnabled
      ? List.generate(8, (i) => 'Player ${i + 1}')
      : [];

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: step == GameSetupStep.createPlayers,
    onPopInvokedWithResult: (didPop, result) {
      switch (step) {
        case GameSetupStep.createPlayers:
          break;
        case GameSetupStep.chooseRoles:
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
        GameSetupStep.chooseRoles => ChooseRolesScreen(
          playerCount: players.length,
          onSubmit: submitChooseRoles,
        ),
      },
    ),
  );

  void submitCreatePlayers(List<String> createdPlayers) {
    setState(() {
      step = GameSetupStep.chooseRoles;
      players = createdPlayers;
    });
  }

  Future<void> submitChooseRoles(
    Map<RoleType, ({Map<String, dynamic> config, int count})> selectedRoles,
  ) async {
    final gameId = await Provider.of<AppDatabase>(
      context,
      listen: false,
    ).gamesDao.createGame(players, selectedRoles);
    widget.onFinished(
      GameSetupResult(
        id: gameId,
        players: players,
        selectedRoles: selectedRoles,
      ),
    );
  }
}

enum GameSetupStep {
  createPlayers,
  chooseRoles;

  String title(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    switch (this) {
      case GameSetupStep.createPlayers:
        return localizations.screen_gameSetup_createPlayers_title;
      case GameSetupStep.chooseRoles:
        return localizations.screen_gameSetup_chooseRoles_title;
    }
  }
}

class GameSetupResult {
  final int id;
  final List<String> players;
  final Map<RoleType, ({int count, RoleConfiguration config})> selectedRoles;

  GameSetupResult({
    required this.id,
    required this.players,
    required this.selectedRoles,
  });
}
