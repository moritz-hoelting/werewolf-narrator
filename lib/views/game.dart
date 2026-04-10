import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/database/database.dart';
import 'package:werewolf_narrator/game/game_data.dart'
    show GamePhase, TransitionToNextPhaseCommand;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/themes.dart';
import 'package:werewolf_narrator/views/game/deaths_screen.dart';
import 'package:werewolf_narrator/views/game/game_setup.dart';
import 'package:werewolf_narrator/views/game/phase_manager_screen.dart';
import 'package:werewolf_narrator/widgets/game/leave_game_dialog.dart';

class GameView extends StatefulWidget {
  const GameView({this.gameId, this.incompleteGameSetup, super.key});

  final int? gameId;
  final IncompleteGameSetup? incompleteGameSetup;

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  late Either<IncompleteGameSetup, GameSetupResult> setupResult;

  @override
  void initState() {
    super.initState();

    setupResult = Either.left(
      widget.incompleteGameSetup ?? IncompleteGameSetup(),
    );

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
          setupResult = Either.right(
            GameSetupResult(
              id: widget.gameId!,
              players: playerNames.map((value) => value.name).toIList(),
              selectedRoles: roleConfigurations.lock,
            ),
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // show spinner while loading game data
    if (widget.gameId != null && setupResult.isLeft()) {
      return const Center(child: CircularProgressIndicator());
    }

    return setupResult.fold(
      (incompleteGameSetup) {
        return GameSetupView(
          initialPlayers: incompleteGameSetup.players,
          initialRoleConfigurations: incompleteGameSetup.roleConfigurations,
          setPlayers: (players) {
            setState(() {
              incompleteGameSetup.players = players;
            });
          },
          setRoles: (roleConfigurations) {
            setState(() {
              incompleteGameSetup.roleConfigurations = roleConfigurations;
            });
          },
          onFinished: (result) {
            setState(() {
              setupResult = Either.right(result);
            });
          },
        );
      },
      (setupResult) {
        if (widget.gameId != null) {
          return FutureBuilder(
            future: GameState.fromDatabase(
              id: widget.gameId!,
              playerNames: setupResult.players,
              roleConfigurations: setupResult.selectedRoles,
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
              return _InnerGameView(
                setupResult: setupResult,
                preparedGameState: gameState,
              );
            },
          );
        }

        return _InnerGameView(setupResult: setupResult);
      },
    );
  }
}

class _InnerGameView extends StatelessWidget {
  const _InnerGameView({required this.setupResult, this.preparedGameState});

  final GameSetupResult setupResult;
  final GameState? preparedGameState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          preparedGameState ??
          GameState(
            id: setupResult.id,
            playerNames: setupResult.players,
            roleConfigurations: setupResult.selectedRoles,
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
