import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_data.dart'
    show GamePhase, TransitionToNextPhaseCommand;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/themes.dart';
import 'package:werewolf_narrator/util/logging.dart' show logger;
import 'package:werewolf_narrator/views/game/deaths_screen.dart';
import 'package:werewolf_narrator/views/game/game_setup.dart';
import 'package:werewolf_narrator/views/game/phase_manager_screen.dart';
import 'package:werewolf_narrator/widgets/game/leave_game_dialog.dart';

class GameView extends StatefulWidget {
  const GameView({this.preparedGameState, this.gameSetup, super.key});

  final Either<IncompleteGameSetup, GameSetupResult>? gameSetup;
  final GameState? preparedGameState;

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  late Either<IncompleteGameSetup, GameSetupResult> setupResult =
      widget.gameSetup ?? Either.left(IncompleteGameSetup());

  @override
  Widget build(BuildContext context) {
    return setupResult.fold(
      (incompleteGameSetup) {
        return GameSetupView(
          initialPlayers: incompleteGameSetup.players,
          initialGameConfiguration: incompleteGameSetup.gameConfiguration,
          initialRoleConfigurations: incompleteGameSetup.roleConfigurations,
          setPlayers: (players) {
            setState(() {
              incompleteGameSetup.players = players;
            });
          },
          setGameConfiguration: (gameConfiguration) {
            setState(() {
              incompleteGameSetup.gameConfiguration = gameConfiguration;
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
        return _RunningGameView(
          setupResult: setupResult,
          preparedGameState: widget.preparedGameState,
        );
      },
    );
  }
}

class _RunningGameView extends StatelessWidget {
  const _RunningGameView({required this.setupResult, this.preparedGameState});

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
            gameConfiguration: setupResult.gameConfiguration,
            roleConfigurations: setupResult.roleConfigurations,
          ),
      child: Consumer<GameState>(
        builder: (context, gameState, child) {
          final showDeathsScreen =
              (gameState.hasPendingDeathAnnouncements ||
                  gameState.firstPlayerWithPendingDeathAction != null) &&
              (!gameState.isNight || gameState.phase == GamePhase.dusk) &&
              !gameState.hasPendingDeathAnnouncementsFromNight;

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
                    logger.info('Leaving game ${gameState.id}');
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
