import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/database/database.dart';
import 'package:werewolf_narrator/game/model/role.dart';
import 'package:werewolf_narrator/game/model/role_config.dart'
    show RoleConfiguration;
import 'package:werewolf_narrator/util/developer_settings.dart';
import 'package:werewolf_narrator/util/settings.dart' show AppSettings;
import 'package:werewolf_narrator/views/game/choose_roles_screen.dart';
import 'package:werewolf_narrator/views/game/create_players.dart';

class GameSetupView extends StatefulWidget {
  final void Function(GameSetupResult) onFinished;
  final IList<String>? initialPlayers;
  final IMap<RoleType, ({Map<String, dynamic> config, int count})>?
  initialRoleConfigurations;

  final void Function(IList<String> players) setPlayers;
  final void Function(
    IMap<RoleType, ({Map<String, dynamic> config, int count})>
    roleConfigurations,
  )
  setRoles;

  const GameSetupView({
    required this.onFinished,
    required this.setPlayers,
    required this.setRoles,
    this.initialPlayers,
    this.initialRoleConfigurations,
    super.key,
  });

  @override
  State<GameSetupView> createState() => _GameSetupViewState();
}

class _GameSetupViewState extends State<GameSetupView> {
  GameSetupStep step = GameSetupStep.createPlayers;

  late IList<String> players;
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
    roleConfigurations = widget.initialRoleConfigurations;
  }

  @override
  Widget build(BuildContext context) => switch (step) {
    GameSetupStep.createPlayers => CreatePlayersScreen(
      onSubmit: submitCreatePlayers,
      initialPlayers: players,
    ),
    GameSetupStep.chooseRoles => ChooseRolesScreen(
      playerCount: players.length,
      onSubmit: submitChooseRoles,
      initialRoles: roleConfigurations,
      onBack: (finalRoles) {
        setState(() {
          step = GameSetupStep.createPlayers;
          roleConfigurations = finalRoles;
        });
      },
    ),
  };

  void submitCreatePlayers(IList<String> createdPlayers) {
    setState(() {
      step = GameSetupStep.chooseRoles;
      players = createdPlayers;
    });
  }

  Future<void> submitChooseRoles(
    IMap<RoleType, ({Map<String, dynamic> config, int count})> selectedRoles,
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

enum GameSetupStep { createPlayers, chooseRoles }

class IncompleteGameSetup {
  IncompleteGameSetup({this.players, this.roleConfigurations});

  IList<String>? players;
  IMap<RoleType, ({int count, RoleConfiguration config})>? roleConfigurations;
}

class GameSetupResult {
  const GameSetupResult({
    required this.id,
    required this.players,
    required this.selectedRoles,
  });

  final int id;
  final IList<String> players;
  final IMap<RoleType, ({int count, RoleConfiguration config})> selectedRoles;
}
