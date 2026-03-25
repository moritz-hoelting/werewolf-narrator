import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/game/game_data.dart' show GamePhase;
import 'package:werewolf_narrator/game/game_state.dart';
import 'package:werewolf_narrator/views/game/dawn.dart';
import 'package:werewolf_narrator/views/game/dusk.dart';
import 'package:werewolf_narrator/views/game/check_roles_screen.dart';
import 'package:werewolf_narrator/views/game/game_over_screen.dart';
import 'package:werewolf_narrator/views/game/dynamic_actions_screen.dart';

class GamePhaseScreen extends StatelessWidget {
  final GamePhase phase;
  final VoidCallback onPhaseComplete;

  const GamePhaseScreen({
    super.key,
    required this.phase,
    required this.onPhaseComplete,
  });

  @override
  Widget build(BuildContext context) {
    switch (phase) {
      case GamePhase.dusk:
        return DuskScreen(
          key: ValueKey(phase),
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.checkRoles:
        return CheckRolesScreen(
          key: ValueKey(phase),
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.nightActions:
        final gameState = Provider.of<GameState>(context, listen: false);
        return DynamicActionsScreen(
          orderedActions: gameState.nightActions,
          actionHooks: gameState.nightActionHooks,
          onAllActionsComplete: onPhaseComplete,
        );
      case GamePhase.dawn:
        return DawnScreen(onPhaseComplete: onPhaseComplete);
      case GamePhase.dayActions:
        final gameState = Provider.of<GameState>(context, listen: false);
        return DynamicActionsScreen(
          orderedActions: gameState.dayActions,
          actionHooks: gameState.dayActionHooks,
          onAllActionsComplete: onPhaseComplete,
        );
      case GamePhase.gameOver:
        return GameOverScreen();
    }
  }
}
