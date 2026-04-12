import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/database/database.dart';
import 'package:werewolf_narrator/game/model/configuration_options.dart'
    show GameConfiguration, RoleConfiguration;
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/util/developer_settings.dart';
import 'package:werewolf_narrator/util/settings.dart' show AppSettings;
import 'package:werewolf_narrator/views/game/choose_roles_screen.dart';
import 'package:werewolf_narrator/views/game/configure_game_screen.dart'
    show ConfigureGameScreen;
import 'package:werewolf_narrator/views/game/create_players.dart';

class GameSetupView extends StatefulWidget {
  final void Function(GameSetupResult) onFinished;
  final IList<String>? initialPlayers;
  final GameConfiguration? initialGameConfiguration;
  final IMap<RoleType, ({Map<String, dynamic> config, int count})>?
  initialRoleConfigurations;

  final ValueChanged<IList<String>> setPlayers;
  final ValueChanged<GameConfiguration> setGameConfiguration;
  final ValueChanged<IMap<RoleType, ({RoleConfiguration config, int count})>>
  setRoles;

  const GameSetupView({
    required this.onFinished,
    required this.setPlayers,
    required this.setGameConfiguration,
    required this.setRoles,
    this.initialPlayers,
    this.initialGameConfiguration,
    this.initialRoleConfigurations,
    super.key,
  });

  @override
  State<GameSetupView> createState() => _GameSetupViewState();
}

class _GameSetupViewState extends State<GameSetupView> {
  GameSetupStep step = GameSetupStep.createPlayers;

  late IList<String> players;
  late GameConfiguration? gameConfiguration;
  late IMap<RoleType, ({Map<String, dynamic> config, int count})>?
  roleConfigurations;

  @override
  void initState() {
    super.initState();

    players =
        widget.initialPlayers ??
        (Provider.of<DeveloperSettings>(
              context,
              listen: false,
            ).fillPlayerNamesEnabled
            ? List.generate(
                AppSettings.instance.minPlayers,
                (i) => 'Player ${i + 1}',
              ).lock
            : const IList.empty());
    gameConfiguration = widget.initialGameConfiguration;
    roleConfigurations = widget.initialRoleConfigurations;
  }

  @override
  Widget build(BuildContext context) => switch (step) {
    GameSetupStep.createPlayers => CreatePlayersScreen(
      onSubmit: submitCreatePlayers,
      initialPlayers: players,
    ),
    GameSetupStep.configureGame => ConfigureGameScreen(
      onSubmit: submitCreateGameConfiguration,
      initialConfiguration: gameConfiguration,
      onBack: (config) {
        setState(() {
          step = GameSetupStep.createPlayers;
          gameConfiguration = config;
        });
      },
    ),
    GameSetupStep.chooseRoles => ChooseRolesScreen(
      playerCount: players.length,
      onSubmit: submitChooseRoles,
      initialRoles: roleConfigurations,
      onBack: (finalRoles) {
        setState(() {
          step = GameSetupStep.configureGame;
          roleConfigurations = finalRoles;
        });
      },
    ),
  };

  void submitCreatePlayers(IList<String> createdPlayers) {
    setState(() {
      step = GameSetupStep.configureGame;
      players = createdPlayers;
    });
  }

  void submitCreateGameConfiguration(GameConfiguration config) {
    setState(() {
      step = GameSetupStep.chooseRoles;
      gameConfiguration = config;
    });
  }

  Future<void> submitChooseRoles(
    IMap<RoleType, ({Map<String, dynamic> config, int count})> selectedRoles,
  ) async {
    final gameId = await Provider.of<AppDatabase>(context, listen: false)
        .gamesDao
        .createGame(
          players,
          gameConfiguration ?? const IMap.empty(),
          selectedRoles,
        );
    widget.onFinished(
      GameSetupResult(
        id: gameId,
        players: players,
        gameConfiguration: gameConfiguration ?? IMap<String, dynamic>(),
        roleConfigurations: selectedRoles,
      ),
    );
  }
}

enum GameSetupStep { createPlayers, configureGame, chooseRoles }

class IncompleteGameSetup {
  IncompleteGameSetup({
    this.players,
    this.gameConfiguration,
    this.roleConfigurations,
  });

  IList<String>? players;
  GameConfiguration? gameConfiguration;
  IMap<RoleType, ({int count, RoleConfiguration config})>? roleConfigurations;
}

class GameSetupResult {
  const GameSetupResult({
    required this.id,
    required this.players,
    required this.gameConfiguration,
    required this.roleConfigurations,
  });

  final int id;
  final IList<String> players;
  final GameConfiguration gameConfiguration;
  final IMap<RoleType, ({int count, RoleConfiguration config})>
  roleConfigurations;
}
