import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/database/database.dart';
import 'package:werewolf_narrator/game/game_data.dart'
    show GamePhase, TransitionToNextPhaseCommand;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/l10n/app_localizations.dart';
import 'package:werewolf_narrator/themes.dart';
import 'package:werewolf_narrator/views/game/deaths_screen.dart';
import 'package:werewolf_narrator/views/game/game_setup.dart';
import 'package:werewolf_narrator/views/game/phase_manager_screen.dart';

class GameView extends StatefulWidget {
  const GameView({this.gameId, super.key});

  final int? gameId;

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  GameSetupResult? setupResult;

  @override
  void initState() {
    super.initState();

    if (widget.gameId != null) {
      final db = Provider.of<AppDatabase>(context, listen: false);

      (
        db.gamesDao.getOrderedPlayerNamesForGame(widget.gameId!),
        db.gamesDao.getRolesForGame(widget.gameId!),
      ).wait.then((results) async {
        final playerNames = results.$1;
        final roleConfigurations = results.$2;

        assert(
          playerNames.isNotEmpty,
          'Game with id ${widget.gameId} not found',
        );

        setState(() {
          setupResult = GameSetupResult(
            id: widget.gameId!,
            players: playerNames,
            selectedRoles: roleConfigurations,
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // show spinner while loading game data
    if (widget.gameId != null && setupResult == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (setupResult != null) {
      if (widget.gameId != null) {
        return FutureBuilder(
          future: GameState.fromDatabase(
            id: widget.gameId!,
            playerNames: setupResult!.players,
            roleConfigurations: setupResult!.selectedRoles,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading game: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final gameState = snapshot.data!;
            return InnerGameView(
              setupResult: setupResult,
              preparedGameState: gameState,
            );
          },
        );
      }

      return InnerGameView(setupResult: setupResult);
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

class InnerGameView extends StatelessWidget {
  const InnerGameView({
    required this.setupResult,
    this.preparedGameState,
    super.key,
  });

  final GameSetupResult? setupResult;
  final GameState? preparedGameState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          preparedGameState ??
          GameState(
            id: setupResult!.id,
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
                    builder: (dialogContext) => const LeaveGameDialog(),
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
