import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:werewolf_narrator/model/role.dart';
import 'package:werewolf_narrator/state/game.dart';
import 'package:werewolf_narrator/views/game/dusk.dart';
import 'package:werewolf_narrator/views/game/check_role_screen.dart';

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
      case GamePhase.checkRoleSeer:
        return CheckRoleScreen(
          key: ValueKey(phase),
          role: Role.seer,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.checkRoleCupid:
        return CheckRoleScreen(
          key: ValueKey(phase),
          role: Role.cupid,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.checkRoleHunter:
        return CheckRoleScreen(
          key: ValueKey(phase),
          role: Role.hunter,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.checkRoleWitch:
        return CheckRoleScreen(
          key: ValueKey(phase),
          role: Role.witch,
          onPhaseComplete: onPhaseComplete,
        );
      case GamePhase.checkRoleWerewolves:
        return CheckRoleScreen(
          key: ValueKey(phase),
          role: Role.werewolf,
          onPhaseComplete: () {
            onPhaseComplete();
            final GameState gameState = Provider.of<GameState>(
              context,
              listen: false,
            );
            gameState.fillVillagerRoles();
          },
        );
      // Add other phases here
      default:
        return Scaffold(
          body: Center(
            child: Text(
              'Phase: $phase',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        );
    }
  }
}
